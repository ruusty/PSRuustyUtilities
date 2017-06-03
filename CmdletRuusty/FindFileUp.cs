using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Management.Automation;
using System.Threading;
using System.Diagnostics;
using System.IO;


namespace Ruusty.PSUtilities
{
    /// <summary>
    /// <para type="synopsis">Find Name by searching upwards from StartDirectory.</para>
    /// <para type="description">Find Name by searching upwards from StartDirectory.</para>
    /// </summary>
    /// <example>
    ///  
    ///   <code>Find-FileUp settings.${env:computername}.xml</code>    
    ///   <para>Find settings.computername.xml from the Current working directory </para>
    /// </example>
    [Cmdlet(VerbsCommon.Find, "FileUp")]
    [OutputType(typeof(String))]
    public class FindFileUpCmdlet : Cmdlet
    {
        /// <summary>
        /// <para type="description">Literal name of file.</para>
        /// </summary>
        [Parameter(Position = 1,Mandatory = true, HelpMessage ="Enter Literal Name of file to find")]
        public string Name { get; set; }
        /// <summary>
        /// <para type="description">Start the search from StartDirectory</para>
        /// <para type="description">Defaults to Curent Working directory</para>
        /// </summary>
        [Parameter(Position = 2, Mandatory = false)]
        public string StartDirectory { get; set; } = Directory.GetCurrentDirectory();
#pragma warning disable 1591
        protected override void BeginProcessing()
        {//initialization
            base.BeginProcessing();
        }


#pragma warning disable 1591
        protected override void ProcessRecord()
        {//process each item in the pipeline
            WriteVerbose(String.Format("Finding {0}", Name));
            string path = FindFileUp(StartDirectory, Name);
            WriteVerbose(String.Format("Returned {0}", path));

            if (String.IsNullOrEmpty(path))
            {
                var ex = new FileNotFoundException("Configuration file not found", Name);
                var errorRecord = new ErrorRecord(ex, Name, ErrorCategory.ObjectNotFound, null);
                ThrowTerminatingError(errorRecord);
            }
            WriteObject(path, false);
        }

        protected override void StopProcessing()
        {//to handle abnormal termination

        }
        protected override void EndProcessing()
        {//do the finalization
            Debug.WriteLine("EndProcessing ThreadId: " + Thread.CurrentThread.ManagedThreadId);
        }

        private string FindFileUp(string cwd, string fileName)
        {
            string startPath = System.IO.Path.Combine(System.IO.Path.GetFullPath(cwd), fileName);
            FileInfo file = new FileInfo(startPath);
            while (!file.Exists)
            {
                if (file.Directory.Parent == null)
                {
                    return null;
                }
                DirectoryInfo parentDir = file.Directory.Parent;
                file = new FileInfo(System.IO.Path.Combine(parentDir.FullName, file.Name));
            }
            return file.FullName;
        }
    }
}
