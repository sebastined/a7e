using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace today
{

    interface IAnimal
    {
        void animalsound();
    }
    class Pig : IAnimal
    {
        public void animalsound()
        {
            Console.WriteLine("The pig says: wee wee");

        }
    }
    public class Program
    {
        static void Main(string[] args)
        {
            Pig mypig = new Pig();
            mypig.animalsound();
        }
    }

}

