using System;


namespace gallant
{
    internal class MyException : Exception
    {
        public MyException() : base() { }
        public MyException(string message) : base(message) { }
        public MyException(string message, Exception innerException) : base(message, innerException) { }

        private string strExtrainfo;
        public string ExtraErrorInfo 
        { 
            get 
            { 
                return strExtrainfo; 
            }
            set 
            {   
                strExtrainfo = value;
            }
        }
    }
}
