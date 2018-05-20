using System;
using System.ComponentModel;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Management.Automation;
using System.Threading;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;

namespace Ruusty.PSUtilities
{
    /// <summary>
    /// <para type="synopsis">Runs an executable with logging</para>
    /// <para type="description">Runs an executable with logging</para>
    /// </summary>
    /// <example>
    ///   <code>Start-Exe -FilePath "sleep.exe" -ArgumentList 5</code>
    ///   <para>Sleep for 5 seconds</para>
    /// </example>
    [Cmdlet(VerbsLifecycle.Start, "Exe")]
    [OutputType(typeof(String))]
    public class StartExeCmdlet : Cmdlet
    {
        Nullable<int> _processId = null;
        //private ProgressRecord _progressRecord;

        //private Task task = null;
        private Task<int> task = null;
        private string[] argCollection;
        string args = string.Empty;

        /// <summary>
        /// <para type="description">Specifies the optional path and file name of the program that runs in the process. Enter the name of an executable file or of a document, such as a .txt</para>
        /// <para type="description">or .doc file, that is associated with a program on the computer. This parameter is required.</para>
        /// <para type="description">If you specify only a file name, use the WorkingDirectory parameter to specify the path.</para>
        /// </summary>
        [Parameter(Position = 1, Mandatory = true, HelpMessage = "help")]
        public string FilePath { get; set; }



        /// <summary>
        /// <para type="description">Specifies parameters or parameter values to use when this cmdlet starts the process.</para>
        /// </summary>
        [Parameter(
            Mandatory = false,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = false,
            Position = 2,
            HelpMessage = "help")]
        public string[] ArgumentList
        {
            get { return argCollection; }
            set { argCollection = value; }
        }


        /// <summary>
        /// <para type="description">Specifies the location of the executable file or document that runs in the process. The default is the current folder.</para>
        /// </summary>
        [Parameter(Position = 3, Mandatory = false)]
        public string WorkingDirectory { get; set; } = Directory.GetCurrentDirectory();



        /// <summary>
        /// <para type="description">Specifies the optional path and file name where the stderr and stdout are written.</para>
        /// </summary>
        [Parameter(Position = 4, Mandatory = false,
            HelpMessage = "Enter log file")]
        public string LogPath { get; set; }



#pragma warning disable 1591
        protected override void BeginProcessing()
        {//initialization
            base.BeginProcessing();

            if (argCollection != null)
            {
                args = String.Join(" ", argCollection);
            }

        }
#pragma warning disable 1591
        protected override void ProcessRecord()
        {//process each item in the pipeline
            try
            {

                task = Task<int>.Factory.StartNew(() =>
                {
                    return Start(FilePath, args, WorkingDirectory, LogPath);
                });
               task.Wait();
               Console.WriteLine(task.Result);
               if (task.Result != 0)
               {
                    var e = new System.Management.Automation.RuntimeException(String.Format("{0} ExitCode:{1}", FilePath, task.Result));
                    var errorRecord = new ErrorRecord(e, "StartExe-Fail", ErrorCategory.InvalidResult, null);
                    WriteError(errorRecord);
               }
            }
            catch (AggregateException ae)
            {
                var errorRecord = new ErrorRecord(ae.InnerException, "StartExe-Fail", ErrorCategory.InvalidResult, null);

                WriteError(errorRecord);
                Console.WriteLine("Task has " + task.Status.ToString());
                Console.WriteLine(ae.InnerException);
            }
            finally
            {
                task.Dispose();
            }

        }
#pragma warning disable 1591
        protected override void StopProcessing()
        {//to handle abnormal termination, When the pipeline tells us to stop
            Debug.WriteLine("Pipeline being terminated");
            Process p = Process.GetProcessById((int)_processId);
            if (p == null || !p.HasExited)
            {
                p.Kill();
            }
        }
#pragma warning disable 1591
        protected override void EndProcessing()
        {//do the finalization
            Debug.WriteLine("EndProcessing ThreadId: " + Thread.CurrentThread.ManagedThreadId);
        }


        private int Start(string filePath, string args = "", string cwd = "", string logPath = "", string verb = "")
        {
            object _locker = new object();
            Trace.WriteLine(string.Format("{0} {1}", filePath, args));

            //* Create your Process
            Process process = new Process();
            process.StartInfo.FileName = filePath;
            process.StartInfo.UseShellExecute = false;
            process.StartInfo.CreateNoWindow = true;
            process.StartInfo.RedirectStandardOutput = false;
            process.StartInfo.RedirectStandardError = false;

            process.StartInfo.RedirectStandardOutput = true;
            process.StartInfo.RedirectStandardError = true;

            bool isLogFileRedirect = (!String.IsNullOrEmpty(logPath));
            //* Set output and error (asynchronous) handlers
            process.OutputDataReceived += (s, e) =>
            {
                if (isLogFileRedirect)
                {
                    lock (_locker)
                    {
                        File.AppendAllLines(logPath, new string[] { e.Data });
                    }
                }
                Console.WriteLine(e.Data);
            };

            process.ErrorDataReceived += (s, e) =>
            {
                if (isLogFileRedirect)
                {
                    lock (_locker)
                    {
                        File.AppendAllLines(logPath, new string[] { "STDERR>", e.Data });
                    }
                }
                Console.WriteLine("STDERR>" + e.Data);
            };

            process.Exited += (s, e) =>
            {
                Console.WriteLine("Exit time:    {0}\r\n" + "Exit code:    {1}\r\n", process.ExitTime, process.ExitCode);
            };


            //* Optional process configuration
            if (!String.IsNullOrEmpty(args)) { process.StartInfo.Arguments = args; }
            if (!String.IsNullOrEmpty(cwd)) { process.StartInfo.WorkingDirectory = cwd; }
            if (!String.IsNullOrEmpty(verb)) { process.StartInfo.Verb = verb; }

            //* Start process and handlers
            try
            {
                process.Start();
                process.BeginOutputReadLine();
                process.BeginErrorReadLine();
                _processId = process.Id;
                process.WaitForExit();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(ex.Message);
                var e = new System.Management.Automation.RuntimeException(String.Format("{0} ExitCode:{1}", FilePath, -1),ex );
                throw (e);
            }
            return process.ExitCode;
        }
    }
}

