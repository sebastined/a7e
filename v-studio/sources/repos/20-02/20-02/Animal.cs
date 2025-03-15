using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace _20_02
{
    public class Animal
    {
        protected string species;
        public string Species;
        {

            get { return species; }
            set { species = value; }
        }
        public void sleep()
        {
            Console.WriteLine("The animal is sleeping in laying");
        }
    }
}
