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
    /// <para type="synopsis">Sets the version strings AssemblyVersion and AssemblyFileVersion in an AssemblyInfo.cs</para>
    /// <para type="description">Preserves encoding</para>
    /// </summary>
    /// <example>
    ///   <code>Set-VersionAssembly AssemblyInfo.cs </code>
    ///   <para>Sets verion to 0.0.0.0</para>
    /// </example>
    [Cmdlet(VerbsCommon.Set, "VersionAssembly")]
    [OutputType(typeof(Version))]
    public class SetVersionAssemblyCmdlet : Cmdlet
    {
        private string[] pathCollection;

        #region

        /// <summary>
        /// <para type="description">Paths of the AssemblyInfo.cs</para>
        /// </summary>
        [Parameter(
            Mandatory = true,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = false,
            Position = 0,
            HelpMessage = "File path(s)")]
        [Alias("AssemblyPath")]
        public string[] Path
        {
            get { return pathCollection; }
            set { pathCollection = value; }
        }

        /// <summary>
        /// <para type="description">Version value</para>
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
                    WriteVerbose(string.Format("Versioning: {0} with Version={1}", name, version.ToString()));
                    RegexAssembly(name, version);
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

        //Using Regex update the Assembly
        private void RegexAssembly(string pFileName, Version  version)
        {
            string s = "";
            System.Text.RegularExpressions.RegexOptions options = System.Text.RegularExpressions.RegexOptions.Multiline;

            string assemblyVersionExp     =     @"(?<ver>AssemblyVersion\s*\(\s*\""[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\""\s*\))";
            System.Text.RegularExpressions.Regex reAssemblyVersion = new System.Text.RegularExpressions.Regex(assemblyVersionExp, options);
        
            string fileVersionExp =  @"(?<ver>AssemblyFileVersion\s*\(\s*\""[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\""\s*\))";
            System.Text.RegularExpressions.Regex reFileVersion = new System.Text.RegularExpressions.Regex(fileVersionExp, options);

            System.Text.Encoding encoding = Helper.GetEncoding(pFileName);
            using (System.IO.StreamReader sr = new System.IO.StreamReader(pFileName))
            {
                s = @sr.ReadToEnd();
            }
            WriteVerbose(string.Format("The encoding used was {0}.", encoding));
            string versionReplacement = String.Format(@"AssemblyVersion(""{0}"")", version.ToString());
            s = reAssemblyVersion.Replace(@s, versionReplacement);

            string fileVersionReplacement = String.Format(@"AssemblyFileVersion(""{0}"")", version.ToString());
            s = reFileVersion.Replace(@s, fileVersionReplacement);

            using (System.IO.StreamWriter sw = new System.IO.StreamWriter(pFileName, false, encoding))
            {
                sw.Write(s);
            }
        }
    }




}
