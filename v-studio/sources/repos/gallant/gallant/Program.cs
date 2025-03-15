using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace gallant
{
    class Program
    {
        static void Main(string[] args)
        {
            try
            {
                string szoveg = "Hello World!";
                int szam = Convert.ToInt32(szoveg);
                Console.WriteLine(szoveg);
            }
            catch (Exception e)
            {
                Console.WriteLine("Hiba történt: " + e.Message);
            }
            Console.ReadKey();
        }
    }
}
