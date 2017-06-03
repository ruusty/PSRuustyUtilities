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
    /// <para type="synopsis">Sets the token @key@ to value in the Path(s)</para>
    /// <para type="description">Same as Nant ReplaceToken</para>
    /// </summary>

    /// <example>
    ///   <code>Set-Token README.md "key" "value"</code>
    ///   <para>Sets the token @key@ to value</para>
    /// </example>
    [Cmdlet(VerbsCommon.Set, "Token")]
    [OutputType(typeof(string))]
    public class SetTokenCmdlet : Cmdlet
    {
        private string[] pathCollection;

        /// <summary>
        /// <para type="description">Path(s) of files to set the target.</para>
        /// </summary>
        [Parameter(
            Mandatory = true,
            ValueFromPipeline = true,
            ValueFromPipelineByPropertyName = false,
            Position = 0,
            HelpMessage = "Enter Path(s) of files")]

        public string[] Path
        {
            get { return pathCollection; }
            set { pathCollection = value; }
        }
        /// <summary>
        /// <para type="description">The token to change. (Case-sensitive)</para>
        /// </summary>
        [Parameter(Position = 1,Mandatory = true)]
        public string key { get; set; }

        /// <summary>
        /// <para type="description">The new value of the token.</para>
        /// </summary>
        [Parameter(Position = 2,Mandatory = true)]
        public string value { get; set; }

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
                WriteVerbose(string.Format("Replacing Token '@{0}@' with '{1}' in {2}", key, value,name));
                try
                {
                    RegexToken(name, key, value);
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

        private void RegexToken(string pFileName, string  key, string value)
        {
            System.Text.RegularExpressions.RegexOptions options = System.Text.RegularExpressions.RegexOptions.Multiline;
            System.Text.RegularExpressions.Regex reToken = new System.Text.RegularExpressions.Regex(@"(?<token>@(" + key  + ")@)", options);
            string s = "";
            System.Text.Encoding encoding = Helper.GetEncoding(pFileName);
            using (System.IO.StreamReader sr = new System.IO.StreamReader(pFileName))
            {
                s = @sr.ReadToEnd();
            }
            WriteVerbose(string.Format("The encoding used was {0}.", encoding));

            string replacement = string.Format("{0}", value);
            s = reToken.Replace(@s, replacement);
            using (System.IO.StreamWriter sw = new System.IO.StreamWriter(pFileName, false, encoding))
            {
                sw.Write(s);

            }
        }
    }
}
