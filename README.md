# SNI Checker App

## Overview
The **SNI Checker App** is a Flutter application designed to verify the Server Name Indication (SNI) support of multiple hosts. This app helps you easily check if a list of domains can be successfully accessed via HTTPS, while also providing a simple way to manage and save host lists, toggle between light and dark themes, and view results in an organized manner.

## Features
- **Input Host List:** Enter a list of hosts manually or load from a text file.
- **Dark and Light Theme Toggle:** Switch between light and dark modes for optimal viewing experience.
- **SNI Verification:** Perform SNI checks on each host and view the status of success or failure.
- **Host Log View:** Results of SNI verification are displayed in a read-only text box to easily keep track of all hosts.
- **Successful Hosts Display:** A separate section for successful hosts, allowing easy copying to the clipboard.
- **Save Hosts:** Save the entered hosts to a local database for later use.
- **Clear Database:** Clear the previously saved hosts and reset the app.

## How to Use
1. **Enter Hosts:** You can type hosts directly into the text field, with each host on a new line.
2. **Load from File:** Click on the **Load from File** button to select a `.txt` file containing a list of hosts.
3. **Check SNI:** Click the **Check SNI** button to initiate the verification process. The app will display the results in the **Hosts Log** box.
4. **View Results:** Successful hosts will be shown in the **Successful Hosts** section. The success and failure counts are also displayed.
5. **Copy to Clipboard:** Click on **Copy to Clipboard** to copy the list of successful hosts.
6. **Toggle Theme:** Use the theme icon in the top right corner of the app bar to switch between light and dark modes.
7. **Clear All:** To reset the list, use the **Clear All** button. This also clears the database of previously saved hosts.

## Dependencies
The app uses several packages to provide the necessary features:
- **http**: To make HTTP requests and perform SNI checks.
- **file_picker**: For selecting and loading a text file containing a list of hosts.
- **sqflite**: To manage local storage of hosts and theme settings.
- **path**: To handle paths for storing the SQLite database.
- **flutter/services.dart**: To enable copying data to the clipboard.

## Installation
1. Clone the repository:
   ```sh
   git clone <repository-url>
   ```
2. Navigate to the project directory:
   ```sh
   cd sni_checker_app
   ```
3. Install dependencies:
   ```sh
   flutter pub get
   ```
4. Run the application:
   ```sh
   flutter run
   ```

## Future Enhancements
- **Add Batch Processing:** Add the ability to process large numbers of hosts in batches for better performance.
- **Improve Error Handling:** Provide detailed error messages for common issues (e.g., network connectivity).
- **Export Results:** Add functionality to export the success/failure results to a file.

## Contributing
Feel free to contribute to the project by creating pull requests or reporting issues. Contributions are always welcome!

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

## Contact
For any questions or suggestions, please reach out via GitHub or email at: [your-email@example.com]

