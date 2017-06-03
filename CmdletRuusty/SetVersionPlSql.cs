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
    /// <para type="synopsis">Sets the version string in a pl/sql file</para>
    /// <para type="description">Sets the version string token in a pl/sql file where there are any token of the format 'n.n.n.n' where n are 1-4 numberics</para>
    /// <para type="description">e.g. '4.3.2.1'</para>
    /// </summary>
    /// <example>
    ///   <code>Set-VersionPlSql</code>
    ///   <para>Sets the version tokens to '0.0.0.0'</para>
    /// </example>
    /// <example>
    ///   <code>Set-VersionPlSql "oms\sql_function\rusty.sql" $(new-object Version(4.3.0.1))</code>
    ///   <para>Sets the version tokens to '4.3.0.1'</para>
    /// </example>
    [Cmdlet(VerbsCommon.Set, "VersionPlSql")]
    [OutputType(typeof(string))]
    public class SetVersionPlSqlCmdlet : Cmdlet
    {
        private string[] pathCollection;

        /// <summary>
        /// <para type="description">Path(s) to set version token in</para>
        /// </summary>
        [Parameter(
            Mandatory = true,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = false,
            Position = 0,
            HelpMessage = "File path")]

        public string[] Path
        {
            get { return pathCollection; }
            set { pathCollection = value; }
        }

        /// <summary>
        /// <para type="description">Version object</para>
        /// </summary>
        [Parameter(Position = 1)]
        public Version version { get; set; } = new Version("0.0.0.0");
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
                WriteVerbose(string.Format("Versioning: {0} with Version={1}", name, version.ToString()));
                try
                {
                    RegexPlSql(name, version);
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

        //Using Regex update the ModuleVersion
        private void RegexPlSql(string pFileName, Version version)
        {//any octet string in single quotes eg '1.2.3.4'
            System.Text.RegularExpressions.RegexOptions options = System.Text.RegularExpressions.RegexOptions.Multiline;
            System.Text.RegularExpressions.Regex reVersion = new System.Text.RegularExpressions.Regex(@"'(?<ver>[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)'",options);
            string s = "";
            System.Text.Encoding encoding = Helper.GetEncoding(pFileName);
            using (System.IO.StreamReader sr = new System.IO.StreamReader(pFileName))
            {
                s = @sr.ReadToEnd();
            }
            WriteVerbose(string.Format("The encoding used was {0}.", encoding));
            string replacement = string.Format("'{0}'", version.ToString());
            s = reVersion.Replace(@s, replacement);
            using (System.IO.StreamWriter sw = new System.IO.StreamWriter(pFileName, false, encoding))
            {
                sw.Write(s);
            }
        }

    }
}
