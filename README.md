# DescriPix
DescriPix: an app for in-depth image analysis and auditory description, enabling targeted insights into selected image areas for enhanced accessibility and understanding

## Getting Started

Before you begin, ensure that you have the following files downloaded:
- DescriPix Swift application file
- serverFlask (Python Flask server file)
- uwsgi.ini (configuration file for uWSGI)

Follow these steps to set up and run the DescriPix server:

1. Open your terminal and navigate to the directory where you have saved the downloaded files.

2. Start the server by executing the following command: `uwsgi --ini uwsgi.ini`

This command initiates the local server and triggers the download of the necessary model for the application to function.

## Configuring the Swift Application

To ensure that the DescriPix Swift application communicates correctly with your local server, you need to update the URL in the application:

1. Open the `UploadImage.swift` class within the DescriPix Swift application.

2. Locate the URL variable and update it with your local server's address (ifconfig).

3. Save the changes and run the application.

## Conclusion

After following these steps, your DescriPix server should be up and running, and the Swift application should be configured to communicate with it. This setup will allow you to start using DescriPix to convert images into vocal descriptions for visually impaired users.

