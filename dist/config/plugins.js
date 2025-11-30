"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.default = ({ env }) => ({
    upload: {
        config: {
            provider: "@strapi/provider-upload-aws-s3",
            providerOptions: {
                accessKeyId: env("AWS_ACCESS_KEY_ID"),
                secretAccessKey: env("AWS_ACCESS_SECRET"),
                region: env("AWS_REGION", "us-east-1"),
                params: {
                    Bucket: env("AWS_S3_BUCKET", "strapi-uploads-bucket-us-east-1"),
                },
            },
        },
    },
});
