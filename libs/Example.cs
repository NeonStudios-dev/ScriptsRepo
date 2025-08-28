using cx;

namespace test
{
    /// <summary>
    /// Example class demonstrating various system operations and checks using the cx library
    /// </summary>
    public class Test
    {
        /// <summary>
        /// Main entry point demonstrating different features of the cx library
        /// </summary>
        /// <param name="args">Command line arguments (not used in this example)</param>
        public static void Main(string[] args)
        {
            // FILE SYSTEM OPERATIONS
            // =====================
            // Check if the Zsh shell executable exists in the system
            // Checks.IfExists: Returns true if the specified path exists (file or directory)
            // Parameters:
            //   - path: The absolute path to check ("/bin/zsh" in this case)
            if (Checks.IfExists("/bin/zsh"))
            {
                Console.WriteLine("Zsh exists");
            }
            else
            {
                Console.WriteLine("Zsh does not exist");
            }

            // PROCESS MANAGEMENT
            // =================
            // Check if PrismLauncher application is running
            // Checks.IsRunning: Verifies if a specific process is running
            // Parameters:
            //   - processName: Name of the process to check ("prismlauncher")
            //   - processID: Process ID (0 means check for any instance)
            //   - ifRunningAction: Action to execute if process is running (lambda expression)
            //   - ifNotRunningAction: Action to execute if process is not running (lambda expression)
            Checks.IsRunning("prismlauncher", 0, 
                // Success callback - executed if process is running
                () =>
                {
                    Console.WriteLine("launcher running is running");
                }, 
                // Failure callback - executed if process is not running
                () =>
                {
                    Console.WriteLine("Zsh is not running");
                });

            // OPERATING SYSTEM DETECTION
            // =========================
            // Display the current operating system name
            // OsChecker.currentOS: Property that returns the current OS name as a string
            Console.WriteLine(OsChecker.currentOS);

            // Detailed OS checks using specific methods
            // Each method returns a boolean indicating if we're running on that OS
            if (OsChecker.IsLinux())
            {
                Console.WriteLine("You are on Linux");
            }
            if (OsChecker.IsMacOS())
            {
                Console.WriteLine("You are on MacOS");
            }
            if (OsChecker.IsWindows())
            {
                Console.WriteLine("You are on Windows");
            }

            // COMMAND EXECUTION EXAMPLES
            // ========================
            // Execute commands with different privilege levels and debug settings
            // cx.commands.ExecuteCommand parameters:
            //   - shell: Shell to use ("" means use system default)
            //   - command: The command to execute
            //   - root: Whether to run with elevated privileges (sudo/admin)
            //   - debug: Whether to show debug information

            // Example 1: Normal user privileges with debug output
            // - No specific shell (uses default)
            // - No root privileges
            // - Debug mode enabled
            cx.commands.ExecuteCommand("", "echo Hello from cx.commands! and with debug!", false, true);
            
            // Example 2: Root privileges without debug output
            // - No specific shell (uses default)
            // - Root privileges enabled (uses sudo on Unix, RunAs on Windows)
            // - Debug mode disabled
            cx.commands.ExecuteCommand("", "echo Hello from cx.commands with root!", true, false);
            
            // Example 3: Root privileges with debug output
            // - No specific shell (uses default)
            // - Root privileges enabled
            // - Debug mode enabled for maximum verbosity
            cx.commands.ExecuteCommand("", "echo Hello from cx.commands with root and debug!", true, true);
            // Example 4: Root privileges with debug output
            // - uses zsh
            // - Root privileges enabled
            // - Debug mode enabled for maximum verbosity
            cx.commands.ExecuteCommand("zsh", "echo Hello from cx.commands with root and debug using zsh!", true, true);

            // PRIVILEGE LEVEL DETECTION
            // ========================
            // Check if the current process has elevated privileges
            // Checks.IsRooted: Returns true if running as root (Linux/macOS) or Administrator (Windows)
            if (Checks.IsRooted() == true)
            {
                Console.WriteLine("You are running as root/administrator");
            }
            else
            {
                Console.WriteLine("You are not running as root/administrator");
            }
        }
    }
}
