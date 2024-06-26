**Note: this is very early testing of the cross-platform functionality of Terminal.Gui with .NET Core.**

# Running Hopper Runtime Console Application on macOS

Follow these steps to run the Hopper Runtime Console application on your macOS machine:

## Prerequisites

- Ensure you have received the zipped file containing the published application (currently in the same folder on GitHub as these instructions).

## Installation and Execution Steps

1. **Unzip the Files**
   - Unzip the received file to a directory on your Mac.
   - You can use Finder to unzip the file or use the following command in Terminal:
     ```sh
     unzip /path/to/yourfile.zip -d /path/to/unzipped/directory
     ```

2. **Open Terminal**
   - Open the Terminal application on your Mac.
   - You can find Terminal in `Applications -> Utilities -> Terminal`.

3. **Navigate to the Application Directory**
   - Use the `cd` command to navigate to the directory containing the unzipped files. For example:
     ```sh
     cd /path/to/unzipped/directory
     ```

4. **Make the Executable Executable**
   - Ensure the main executable file has execute permissions. Run the following command, replacing `Hopper` with the actual name of the executable if it's different:
     ```sh
     chmod +x Hopper
     ```

5. **Run the Application**
   - Run the executable from the Terminal:
     ```sh
     ./Hopper
     ```

## Troubleshooting

- If you encounter any issues with permissions or execution, ensure the file has execute permissions and you are in the correct directory.

- If you see an error regarding missing libraries or dependencies, ensure the zipped file was unzipped correctly and all files are present.

- For any other issues, please provide the error message so we can assist further.

## Additional Notes

- **No Additional Installations Required**: This application is self-contained, meaning all necessary libraries and dependencies are included. You do not need to install .NET Core or any other runtime separately.

---

Feel free to reach out if you need any additional help or encounter any issues. Happy testing!
