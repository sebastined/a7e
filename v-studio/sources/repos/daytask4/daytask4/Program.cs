using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace 
{
    public class person
    {
        protected string ssn = "444-55-6666";
    protected string name = "John Doe";

    public virtual void GetInfo()
    {
        Console.WriteLine("Name: {0}", name);
        Console.WriteLine("SSN: {0}", ssn);
    }
}

class employee : person
{
    public string id = "ABC567EFG";
    public override void GetInfo()
    {
        base.GetInfo();
        Console.WriteLine("Employee ID: {0}", id);
    }
}

class TestClass
{
    static void Main()
    {
        employee E = new employee();
        E.GetInfo();
    }
}
}