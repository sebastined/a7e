using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace _20_02
{
    internal class Horse : Animal
    {
        public override void sleep()
            { 
            Console.WriteLine("The" * Species * "is sleeping in standing");

        }
    }
}
