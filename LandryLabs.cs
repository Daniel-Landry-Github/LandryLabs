// See https://aka.ms/new-console-template for more information
using System;
using System.IO;
using System.Net.Mail;

/*--------------------To Do:
 * -Build the barebones functions of this program to showcase and interact with the existing powershell scripts.
 * -Now that there is a dedicated 'landrylabs.bot@sparkhound.com' mailbox to act as the assistant:
 *      Look into how it can grab new mail and process it's subject and contents (using keywords?) to trigger certain tasks to run and email the results back to the sender.
 *      Should it scan exchange's mailflow to detect mail incoming to 'landrylabs.bot' address (also see if it can detect the folder the mail is received into?)
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
            else if (TaskSelection == term)
            {
                Console.WriteLine("You chose the termination task.");
                Terminate(args);
            }
        }

        static void Onboard(string[] args)
        {
            //System.Diagnostics.Process.Start("C:\\Users\\daniel.landry\\Desktop\\Onboarding.ps1");
            
            //Variables needed for Active Directory user object creation.
            Console.WriteLine("Starting the onboarding task...");
            Console.WriteLine("Please submit the following information:");
            Console.WriteLine("New User First Name: "); string FirstName = Console.ReadLine();
            Console.WriteLine("New User Last Name: "); string LastName = Console.ReadLine();
            string Name = (FirstName + " " + LastName);
            string Username = (FirstName + "." + LastName);
            string EmailAddress = (Username + "@sparkhound.com");
            Console.WriteLine("New User Title: "); string Title = Console.ReadLine();
            Console.WriteLine("New User Region: "); string Region = Console.ReadLine();
            Console.WriteLine("New User Phone Number: "); string PhoneNumber = Console.ReadLine();
            Console.WriteLine("New User Personal Email: "); string PersonalEmail = Console.ReadLine();
            Console.WriteLine("New User Company: "); string Company = Console.ReadLine();
            string Sparkhound = "Sparkhound";
            if (Company != Sparkhound)
            {
                Console.WriteLine("Assigning " + Username + " as a contractor."); string Contractor = "Y"; Title = "Contractor (" + Company + ")";
            }
            else
            {
                string Contractor = "N";
            }
            Console.WriteLine("New User Manager: "); string Manager = Console.ReadLine();
            //Variables needed for Active Directory user object creation.

            Console.WriteLine(FirstName);
            Console.WriteLine(LastName);
            Console.WriteLine(Name);
            Console.WriteLine(Username);
            Console.WriteLine(EmailAddress);
            Console.WriteLine(Title);
            Console.WriteLine(Region);
            Console.WriteLine(PhoneNumber);
            Console.WriteLine(PersonalEmail);

            
        }

        static void Manager(string[] args)
        {
            
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