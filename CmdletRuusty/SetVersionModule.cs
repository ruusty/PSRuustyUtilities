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
    /// <para type="synopsis">Sets the Version in a PowerShell Module Manifest</para>
    /// <para type="description">Sets the Version in a PowerShell Module Manifest</para>
    /// </summary>
    /// <example>
    ///   <code>Set-VersionModule md2html.psd1</code>
    ///   <para>Sets the Modules version to 0.0.0.0</para>
    /// </example>
    [Cmdlet(VerbsCommon.Set, "VersionModule")]
    [OutputType(typeof(Version))]
    public class SetVersionModuleCmdlet : Cmdlet
    {
        private string[] pathCollection;

        #region
        /// <summary>
        /// <para type="description">Path(s) of Module Manifest </para>
        /// </summary>
        [Parameter(
            Mandatory = true,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = false,
            Position = 0,
            HelpMessage = "Name to get Module File path.")]
        [Alias("ModulePath")]
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
        #endregion
#pragma warning disable 1591
        protected override void BeginProcessing()
        {//initialization
            base.BeginProcessing();
        }
#pragma warning disable 1591
        protected override void ProcessRecord()
        {
            foreach (string name in pathCollection)
            {
                try
                {
                    WriteVerbose(string.Format("Versioning: {0} with Version={1}", name,version.ToString()));
                    RegexVersionModule(name, version);
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
        //	ModuleVersion = '1.0.0.0'
        private void RegexVersionModule(string pFileName, Version  version)
        {
            string s = "";
            string regex = @"(?<mod>^\s*ModuleVersion\s*=\s*)(?<ver>('[0-9.]+'))";
            System.Text.Encoding encoding = Helper.GetEncoding(pFileName);
            using (System.IO.StreamReader sr = new System.IO.StreamReader(pFileName))
            {
                s = @sr.ReadToEnd();
            }
            WriteVerbose(string.Format("The encoding used was {0}.", encoding));

            System.Text.RegularExpressions.RegexOptions options = System.Text.RegularExpressions.RegexOptions.Multiline;
            System.Text.RegularExpressions.Regex re = new System.Text.RegularExpressions.Regex(regex, options);
            string replacement = String.Format("${{mod}}'{0}'", version.ToString());
            s = re.Replace(@s, replacement);
            using (System.IO.StreamWriter sw = new System.IO.StreamWriter(pFileName, false, encoding))
            {
                sw.Write(s);
            }
        }
    }




}
