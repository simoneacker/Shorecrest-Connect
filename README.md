# AWS Setup

### S3:
- Bucket for messages testbed system
- Bucket hosting static files for www.shorecrestconnect.com
    - Bucket configured with static hosting, a name that matches the web address, and a policy that makes all objects get-able
    - Static website is not encrypted currently

### RDS:
- MySQL database (currently setup with scconnect database for messages testbed system)

### Elastic Beanstalk (EB):
- One application (with one environment) running the nodejs backend for the messages testbed system
    - Running with load balancer using the *.shorecrestconnect.com cert to secure listen on port 443 (encrypts/decrypts all data and passes unencrypted http to nodejs app)
        - Load balancer also listens on 80, which passes unencrypted http to nodejs app
    - Want to add a njinx script to redirect all http traffic to https

### Certificate Manager:
- One ssl cert for *.shorecrestconnect.com

### Route 53:
- Registration for shorecrestconnect.com
- One record set directing api.shorecrestconnect.com to the EB application endpoint
- One record set directing www.shorecrestconnect.com to S3 static endpoint

### Cognito:
- One identity pool (under federated identities) used to upload/download media from iOS messages testbed to S3 bucket