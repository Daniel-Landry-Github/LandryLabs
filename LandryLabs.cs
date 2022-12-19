// See https://aka.ms/new-console-template for more information
using System;
using System.IO;
using System.Net.Mail;

/*--------------------To Do:
 * -Build the barebones functions of this program to showcase and interact with the existing powershell scripts.
--------------------*/

/*--------------------Change Log:
 * o Added 'Main' method and populated with veribage for intended tasks.
 * o Added 'Onboarding' method to begin gathering information to push to the onboarding powershell script.
--------------------*/

namespace LandryLabs
{
    class Program
    {
        static void Main(string[] args)
        {
            string onboard = "onboard";
            string term = "term";
            Console.WriteLine("LandryLabs bot. Seeks to automate select tasks.");
            Console.WriteLine("The following options are currently available for starting tasks...");
            Console.WriteLine("1) Type 'onboard' to onboard a new hire.");
            Console.WriteLine("2) Type 'term' to terminate an existing user.");
            Console.WriteLine("Please select a task to begin.");

            string TaskSelection = Console.ReadLine();
            if (TaskSelection == onboard)
            {
                Console.WriteLine("You chose the onboarding task.");
                Onboard(args);
            }
            else if(TaskSelection == term)
            {
                Console.WriteLine("You chose the termination task.");
                Terminate(args);
            }
        }

        static void Onboard(string[] args)
        {
            Console.WriteLine("Starting the onboarding task...");

        }

        static void Terminate(string[] args)
        {
            Console.WriteLine("Starting the termination task...");
        }

        static void Testing(string[] args)
        {
            /*Console.WriteLine("Enter your name");
            String Name = Console.ReadLine();
            Console.WriteLine("Welcome "+Name+"!");
            Console.WriteLine("Your name is "+Name.Length+" letters long");
            Console.WriteLine("Do you have a last name? Type Yes/No");
            String LastNameAgreement = Console.ReadLine();
            if (LastNameAgreement != ("No"))
            {
                Console.WriteLine("Please enter your last name now...");
                String LastName = Console.ReadLine();
                Console.WriteLine("Your name is " + Name +" "+ LastName + " and is " + (Name.Length+LastName.Length) + " letters long.");
            }

            else 
            {
                Console.WriteLine("Goodbye.");
            }
            
            string EmailPath = "'C:\\Users\\daniel.landry\\OneDrive - Sparkhound Inc\\LandryLabs\\ExtractedEmail.txt'";
            string ExtractEmail = File.ReadAllLines(EmailPath);
            */


        }
    }
}