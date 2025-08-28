using cx;
namespace test
{
    public class Test
    {
        public static void Main(string[] args)
        {
            // Check if Zsh shell exists in the system
            if (Checks.IfExists("/bin/zsh"))
            {
                Console.WriteLine("Zsh exists");
            }
            else
            {
                Console.WriteLine("Zsh does not exist");
            }

            // Check if PrismLauncher is running (using processID 0 to check for any instance)
            Checks.IsRunning("prismlauncher", 0, () =>
            {
                Console.WriteLine("launcher running is running");
            }, () =>
            {
                Console.WriteLine("Zsh is not running");
            });

            // Display the current operating system
            Console.WriteLine(OsChecker.currentOS);

            // Check specific operating systems and display appropriate messages
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

            // Execute various commands with different combinations of root access and debug mode
            // Empty string for shell parameter uses the default shell
            // Execute command without root, with debug
            cx.commands.ExecuteCommand("", "echo Hello from cx.commands! and with debug!", false, true);
            
            // Execute command with root access, without debug
            cx.commands.ExecuteCommand("", "echo Hello from cx.commands with root!", true, false);
            
            // Execute command with both root access and debug
            cx.commands.ExecuteCommand("", "echo Hello from cx.commands with root and debug!", true, true);

            // Check if the current process is running with elevated privileges (root/administrator)
            if(Checks.IsRooted() == true)
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
