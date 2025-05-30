using System;
using Swicli.Library;
using System.Runtime.InteropServices;
using System.Drawing;
using System.Security;
namespace MettaLogTests
{
    public static class example3
    {
        static example3()
        {
            Console.WriteLine("MettaLogTests::example3.<clinit>()");
        }
        
        public static void Main(String[] args)
        {
			ExecuteWithExceptionHandling(() => PrologCLR.ClientReady = true, "Set PrologCLR.ClientReady");
			//ExecuteWithExceptionHandling(PrologCLR.cliDynTest_1, nameof(PrologCLR.cliDynTest_1));
            //ExecuteWithExceptionHandling(() => PrologCLR.cliDynTest_3<string>(), nameof(PrologCLR.cliDynTest_3));
            //ExecuteWithExceptionHandling(PrologCLR.cliDynTest_2, nameof(PrologCLR.cliDynTest_2));
            //ExecuteWithExceptionHandling(MettaLogTestsWindows.install, nameof(MettaLogTestsWindows.install));
            //ExecuteWithExceptionHandling(() => SWICFFITestsWindows.WinMain(args), nameof(MettaLogTestsWindows.WinMain));
			//ExecuteWithExceptionHandling(() => PrologCLR.When_Main_Was_Test(args), nameof(PrologCLR.When_Main_Was_Test));
			ExecuteWithExceptionHandling(() => PrologCLR.Main(args), nameof(PrologCLR.Main));
        }

        private static void ExecuteWithExceptionHandling(Action action, string actionName)
        {
            try
            {
				Console.WriteLine($"Starting,,, {actionName}:");
                action();
				Console.WriteLine($"Finished,,, {actionName}:");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"An error occurred in {actionName}: {ex.Message}");
                // Optionally, log the exception or handle it as needed
            }
        }

        public static void install()
        {
            Console.WriteLine("MettaLogTests::example3.install()");
            //Console.WriteLine("example3::install press ctrol-D to leave CSharp");
            //System.Reflection.Assembly.Load("csharp").EntryPoint.DeclaringType.GetMethod("Main", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Static).Invoke(null, new object[] { new String[0] });
        }
    }
 
}
