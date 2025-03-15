// See https://aka.ms/new-console-template for more information
namespace _20_02
{
    class Program
    {
        static void Main(string[] args)
        {
            System.Console.WriteLine(SimpleClass.baseline);
            TimePeriod tp = new TimePeriod();
            double x = 10;
            tp.Hours = x;
            if ( x < 0 || x > 24)
            {
                throw new Exception("it should be more");

            }
            Person person = new Person("John", "Doe");
            Console.WriteLine("The name of the person" + person.Name);
            Console.WriteLine("Check"+tp.Hours);
            B b = new B();
            b.Method();
            C c = new C();
            c.Method();
            D d = new D();
            d.Method();
            Person person2 = new Person("John", "Doe", 25, 1);

            Horse horse = new Horse();
            Tiger tiger = new Tiger();
            Monkey monkey = new Monkey();
            horse.sleep();
            tiger.sleep();
            monkey.sleep();

            Console.ReadLine();
        }
    }
}

public class SimpleClass
{
    public static readonly long baseline;

    static SimpleClass()
    {
        baseline = DateTime.Now.Ticks;
    }
}

public class A
{
    public void Method()
    {
        Console.WriteLine("This is the public class A");
    }
}
public class B : A
{

}

public class C : B
{
    public void Method()
    {
        Console.WriteLine("This is the public class C");
    }

}

public class D : C
{

}