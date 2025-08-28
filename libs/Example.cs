using cx;
namespace test

{
    public class Test
    {
        public static void Main(string[] args)
        {
            if (Checks.IfExists("/bin/zsh"))
            {
                Console.WriteLine("Zsh exists");
            }
            else
            {
                Console.WriteLine("Zsh does not exist");
            }
            Checks.IsRunning("prismlauncher", 0, () =>
            {
                Console.WriteLine("launcher running is running");
            }, () =>
            {
                Console.WriteLine("Zsh is not running");
            });
            Console.WriteLine(OsChecker.currentOS);
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
            cx.commands.ExecuteCommand("", "echo Hello from cx.commands! and with debug!", false, true);
            cx.commands.ExecuteCommand("", "echo Hello from cx.commands with root!", true, false);
            cx.commands.ExecuteCommand("", "echo Hello from cx.commands with root and debug!", true, true);
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