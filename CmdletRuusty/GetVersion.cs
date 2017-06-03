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
    /// <para type="synopsis">Creates a Version using StartDate and Now</para>
    /// <para type="description">Creates a Version object of type Major.Minor.Build.Revision </para>
    /// <para type="description">Uses the number of months since start of StartDate * 100 + current day in month as build number.</para>
    /// <para type="description">Uses the number of seconds since the start of today / 10. as the revision number</para>
    /// <para type="description">Same algorithm as Nant</para>
    /// </summary>
    /// <example>
    /// <code>Get-Version 4 3 </code>
    /// <para>Create a Version from  "2012-01-01" using Major 4 Minor 3</para>
    /// </example>
    [Cmdlet(VerbsCommon.Get, "Version")]
    [OutputType(typeof(Version))]
    public class GetVersionCmdlet : Cmdlet
    {
        /// <summary>
        /// <para type="description">Major number</para>
        /// </summary>
        [Parameter(Position = 1)]
        public int Major { get; set; } = 0;
        /// <summary>
        /// <para type="description">Minor number</para>
        /// </summary>
        [Parameter(Position = 2)]
        public int Minor { get; set; } = 0;
        /// <summary>
        /// <para type="description">Start Date to calculate Build number using MonthDay Alglorithm</para>
        /// </summary>
        [Parameter(Position = 3)]
        public DateTime StartDate { get; set; } = DateTime.ParseExact("2012-01-01", "yyyy-MM-dd", System.Globalization.CultureInfo.InvariantCulture);
#pragma warning disable 1591
        protected override void BeginProcessing()
        {//initialization
            base.BeginProcessing();
        }
#pragma warning disable 1591
        protected override void ProcessRecord()
        {//process each item in the pipeline
            try {
                WriteObject(CalculateVersion());
            }
            catch ( Exception ex ) {
                 var errorRecord = new ErrorRecord(ex, "CalculateVersion", ErrorCategory.InvalidResult, null);
                WriteError(errorRecord);
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

        private int CalculateMonthDayBuildNumber()
        {
            // we need to have a start date defined!
            if (StartDate == DateTime.MinValue)
            {
                throw new Exception("\"startdate\" must be set when the" + "\"MonthDay\" algorithm is used.");
            }

            DateTime today = DateTime.Now;
            if (StartDate > today)
            {
                throw new Exception("Start date cannot be in the future.");
            }

            // Calculate difference in years
            int years = today.Year - StartDate.Year;

            // Calculate difference in months
            int months;
            if (today.Month < StartDate.Month)
            {
                --years;  // borrow from years
                months = (today.Month + 12) - StartDate.Month;
            }
            else
            {
                months = today.Month - StartDate.Month;
            }

            months += years * 12;

            // The days is simply today's day
            int days = today.Day;

            return months * 100 + days;
        }

        /// <summary>
        /// Calculates the number of seconds since midnight.
        /// start date.
        /// </summary>
        /// <returns>
        /// The number of seconds since midnight.
        /// </returns>
        private int CalculateSecondsSinceMidnight()
        {
            DateTime today = DateTime.Now;
            return (today.Hour * 3600 + today.Minute * 60 + today.Second) / 10;
        }

        private Version CalculateVersion()
        {
            int newBuildNumber = CalculateMonthDayBuildNumber();
            int newRevisionNumber = CalculateSecondsSinceMidnight();
            return new Version(Major, Minor, newBuildNumber, newRevisionNumber);
        }
    }

}
