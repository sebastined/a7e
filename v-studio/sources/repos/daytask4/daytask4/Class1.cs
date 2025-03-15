using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace daytask4
{
    public class BaseClass
    {
        int num;

        public BaseClass()
        {
            Console.WriteLine("in BaseClass()");
        }
        public BaseClass(int i)
        {
            num = i;
            Console.WriteLine("in BaseClass(int i)");
        }
        public int GetNum()
        {
            return num;
        }
    }
    public class DerivedClass : BaseClass
    {
        public DerivedClass() : base()
        {
            Console.WriteLine("in DerivedClass()");
        }
        public DerivedClass(int i) : base(i)
        {
            Console.WriteLine("in DerivedClass(int i)");
        }
        static void Main()
        {
            DerivedClass MDerivedClass = new DerivedClass();
            DerivedClass MDerivedClass1 = new DerivedClass(10);
        }

    }
}
