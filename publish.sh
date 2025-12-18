#!/bin/bash

# Support for Amazon Linux 2 and 2023
AL_VERSION="${1:-al2}"

if [ "$AL_VERSION" = "al2" ]; then
    LAYER_ZIP="layer.zip"
    VERSION_SUFFIX=""
elif [ "$AL_VERSION" = "al2023" ]; then
    LAYER_ZIP="layer-al2023.zip"
    VERSION_SUFFIX="-al2023"
else
    echo "Error: Unsupported Amazon Linux version '$AL_VERSION'"
    echo "Usage: $0 [al2|al2023]"
    exit 1
fi

VERSION="0.12.6"
ARN_DIR="arns/$VERSION$VERSION_SUFFIX"
ARN_FILE="$ARN_DIR/wkhtmltopdf.csv"
LAYER_NAME="wkhtmltopdf-$VERSION$VERSION_SUFFIX"
LAYER_NAME=${LAYER_NAME//./_} # Replace . with _ , since . is not allow
REGIONS=$(cat config/regions.txt)

# Exit if aws cli is not available
if ! aws --version 1>/dev/null; then
    exit 1
fi

rm -rf $ARN_DIR && mkdir -p $ARN_DIR

echo "Region,ARN" >$ARN_FILE
for region in $REGIONS; do
    printf "%s\n" "Region: $region"
    DESCRIPTION="wkhtmltopdf $VERSION (with patched qt)"
    if [ "$AL_VERSION" = "al2023" ]; then
        DESCRIPTION="$DESCRIPTION - Amazon Linux 2023"
    fi
    OUTPUT=$(
        aws lambda publish-layer-version \
            --description "$DESCRIPTION" \
            --layer-name $LAYER_NAME \
            --output text \
            --query "[LayerVersionArn, Version]" \
            --region $region \
            --zip-file fileb://$LAYER_ZIP
    )
    LAYER_VERSION_ARN=$(echo $OUTPUT | awk '{print $1}')
    LAYER_VERSION=$(echo $OUTPUT | awk '{print $2}')
    aws lambda add-layer-version-permission \
        --action lambda:GetLayerVersion \
        --layer-name $LAYER_NAME \
        --output text \
        --principal "*" \
        --query "Statement" \
        --region "$region" \
        --statement-id public \
        --version-number "$LAYER_VERSION" \
        &>/dev/null
    echo "$region,$LAYER_VERSION_ARN" >>$ARN_FILE
    printf "\n"
done
