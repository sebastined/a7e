// See https://aka.ms/new-console-template for more information
interface IAnimal
{
    void animalsound();
    class Pig : IAnimal
    {
        public void animalsound()
        {
            Console.WriteLine("The pig says: wee wee");
        }
    }
}   
