# Shorecrest-Connect App

The Shorecrest-Connect App is an iOS application that will offer students with many features related to ASB and extracurricular activities. The app was developed by the Computer Science Club at Shorecrest High School.

## Change-log (by version)

### 1.0
* Adds Events Calendar
* Adds Announcements
* Adds Voting

## How to Install

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


## How to Contribute

To contribute to this project, please follow the instructions below. If you have any difficulties, please [email us](mailto:shorecrest.cs.club@gmail.com).

1. Download the [GitHub Desktop App](https://desktop.github.com).
2. Login to the GitHub Desktop App.
3. Please visit the [GitHub page](https://github.com/simoneacker/Shoreline-Connect) of this project and go to the issues section. Please open a new issue titled "Add me as a collaborator". Submit that issue and wait until you have been accepted or denied. Do not continue this guide until you are a collaborator because nothing will work correctly.
4. Once you are a collaborator, please go back to the GitHub Desktop App. Find the "+" button and click it. Then choose clone and select the Shoreline-Connect project. Finally, choose where you want it to store the files on your machine. Once you do that, it will download the files to your machine.
5. Next, please find the "New Branch" button to the left of the branch selection button (the branch selection button will say Developer or master). Click the "New Branch" button and give it your first name for the "name" field. Then choose the developer branch for the "from" field. From then on, please only commit code to your branch.
6. Now that you have your own branch, please visit the following [spreadsheet](https://docs.google.com/spreadsheets/d/1lWivuwWllugYBN1YGXeJNHh8aht-5EAi8nOw8arR7Us/edit?usp=sharing) to decide what you want to work on. Once you have decided, please [email us](mailto:shorecrest.cs.club@gmail.com) so we can know what sections are covered.
7. Congratulations, you are now ready to work on the project and contribute. Thanks for getting this far. Please [contact us](mailto:shorecrest.cs.club@gmail.com) if you have questions or comments.

## Resources

 * [Stanford Course](https://itunes.apple.com/us/course/developing-ios-9-apps-swift/id1104579961) for learning iOS development
 * [Lynda](https://www.lynda.com) -> search for iOS and other programming courses (free with kcls library account)
 * [youtube.com](https://www.youtube.com) more video courses
