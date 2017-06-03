using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Management.Automation;
using System.Threading;
using System.Diagnostics;

namespace Ruusty.PSUtilities
{
    /// <summary>
    /// <para type="synopsis">Stamp the Version and Date on Path/s</para>
    /// <para type="description">The Date is identifified with Date:</para>
    /// <para type="description">The Version is identifified with Version:</para>
    /// </summary>
    /// <example>
    ///   <code>Set-VersionReadme README.md </code>
    ///   <para>Set the version 0.0.0.0 and current date to README.md</para>
    /// </example>
    /// <example>
    ///   <code>Set-VersionReadme README.md Version(4.3.1.2) $(DateTime.Now)</code>
    ///   <para>Set the version 4.3.1.2 and current date to README.md</para>
    /// </example>
    [Cmdlet(VerbsCommon.Set, "VersionReadme")]
    [OutputType(typeof(string))]

    public class SetVersionReadmeCmdlet : Cmdlet
    {
        private string[] pathCollection;
        private const string dateTimeFormat =@"yyyy-MM-ddTHH-mm";
        /// <summary>
        /// <para type="description">Paths to version</para>
        /// </summary>
        [Parameter(
            Mandatory = true,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = false,
            Position = 0,
            HelpMessage = "Path(s) of files to version")]
        public string[] Path
        {
            get { return pathCollection; }
            set { pathCollection = value; }
        }
        /// <summary>
        /// <para type="description">Version to set</para>
        /// </summary>
        [Parameter(Position = 1,
            HelpMessage = "Enter Version as a string e.g 4.3.1.2")]
        public Version version { get; set; } = new Version("0.0.0.0");
        /// <summary>
        /// <para type="description">DateTime defaults to now.</para>
        /// </summary>
        [Parameter(Position = 2)]
        public DateTime datetime { get; set; } = DateTime.Now;
#pragma warning disable 1591
        protected override void BeginProcessing()
        {//initialization
            base.BeginProcessing();
        }
#pragma warning disable 1591
        protected override void ProcessRecord()
        {//process each item in the pipeline

            foreach (string name in pathCollection)
            {
                WriteVerbose(string.Format("Versioning: {0} with Version={1}, DateTime={2}", name,version.ToString(),datetime.ToString(dateTimeFormat)));
                try
                {
                    RegexVersionReadme(name, version, datetime);
                }
                catch (Exception ex)
                {
                    var errorRecord = new ErrorRecord(ex, "Processing file " + name, ErrorCategory.WriteError, null);
                    ThrowTerminatingError(errorRecord);
                }
            }
        }
#pragma warning disable 1591
        protected override void StopProcessing()
        {//to handle abnormal termination

        }
#pragma warning disable 1591
        protected override void EndProcessing()
        {//do the finalization
            Debug.WriteLine("EndProcessing ThreadId: " + Thread.CurrentThread.ManagedThreadId);
        }
        /* The Version and date
Version:        4.3
Date:           2017-04-03
         * */
        private void RegexVersionReadme(string pFileName, Version version, DateTime date)
        {
            System.Text.RegularExpressions.RegexOptions options = System.Text.RegularExpressions.RegexOptions.Multiline;
            System.Text.RegularExpressions.Regex reVersion = new System.Text.RegularExpressions.Regex(@"(?<ver>Version:\s*)([0-9.]+)");
            System.Text.RegularExpressions.Regex reDate = new System.Text.RegularExpressions.Regex(@"(?<date>Date:\s*)([\w \d\-\/\.T\:]*)", options);
            string s = "";
            System.Text.Encoding encoding = Helper.GetEncoding(pFileName);
            using (System.IO.StreamReader sr = new System.IO.StreamReader(pFileName))
            {
                s = @sr.ReadToEnd();
            }
            WriteVerbose(string.Format("The encoding used was {0}.", encoding));

            string replacementVersion = string.Format("${{ver}}{0}", version.ToString());
            string replacementDate = string.Format("${{date}}{0}", date.ToString(dateTimeFormat));

            s = reVersion.Replace(@s, replacementVersion);
            s = reDate.Replace(@s, replacementDate);

            using (System.IO.StreamWriter sw = new System.IO.StreamWriter(pFileName, false, encoding))
            {
                sw.Write(s);
            }
        }


    }
}
