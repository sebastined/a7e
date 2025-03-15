using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace _20_02
{
    public class Person
    {
        private string _firstName;
        private string _lastName;
        private int age;
        private int ID;

        public Person()
        {
            
        }


        public Person(string firstName, string lastName, int age, int iD)
        {
            _firstName = firstName;
            _lastName = lastName;
            this.age = age;
            ID = iD;
        }
        public string Name => $"{_firstName } {_lastName}";

        public void Getinformation()
        {
            Console.WriteLine("The name of the person" + Name);
        }

    };
}
