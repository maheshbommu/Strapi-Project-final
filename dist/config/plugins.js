"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.default = ({ env }) => ({
    upload: {
        config: {
            provider: "aws-s3",
            providerOptions: {
                region: "us-east-1",
                params: {
                    Bucket: "strapi-uploads-bucket-us-east-1",
                },
            },
        },
    },
});
