# Summit2017
PowerShell Global Summit 2017 Content

# Reading Materials
* [Meta Programming PowerPoint](https://docs.google.com/presentation/d/18GUjnqlSks_H7NvZq7xdpnjfirY3qYe20-zEPZeRHFY/edit?usp=sharing)
* [Speech Outline](https://docs.google.com/document/d/1H9mmOi9aSB884U10rhFSn81GTISlYLSul43se8i4s5A/edit?usp=sharing)

# What this is and how to use it
This is my collection of files from the PowerShell Global Summit 2017 for my lightning demo on [Meta Programming](https://en.wikipedia.org/wiki/Metaprogramming) with PowerShell
Included in this repo are 4 sample script files.
Demo1_Puppy_Killer.ps1 - This example is randomly generating a bunch of static Write-Host lines to randomly select a foreground and background color. It builds the code line by line and then writes it out to a static file.

Demo2_Unit_Testing_Outline.ps1 - This example builds a pester unit test outline for every cmdlet in a module. The inspiration for this is I'm an engineer and I am truly lazy at heart. Why would I waste time writing an outline by hand, when a simple PowerShell script can do it for me in 20 lines with indentation!

Demo3_Switch_Statement.ps1 - This example was the inspiration for the entire talk, it comes from some sample code at work. In which we do SQL merges of data from multiple AD domains into a SQL Server DB. We opted for merges on the sql server, other doing the comparisons on the client side. In this demo, specifically lines 119 (Switch statement) and below are the important lines. The switch statement runs to figure out what logic needs to be applied in the @""@ block of text. Inside the block of text, it uses a series of nested if statements and environment variables from the system, to see what logic needs to be applied. You will see in this example I have the original formatted code, and then it broken apart with code indentation. The reason it’s not broken apart by default is because it causes the SQL code indentation to be off when fully executed. Below this are 3 example of running the code with no environment variables, no switch statement, and then fully executed. This is shown for the user to fully understand the potential for bugs to occur with Meta Programming. I can speak to personal experience on this as well, when I forgot to run the switch statement. I dropped about 300K rows of data form my dev database by simply not running the switch statement while testing. (DISCLAIMER: This example will not work in any enviroment as it is specific to an application I wrote)

Demo4_AD_Sites_And_Services_Backup.ps1 - This example was inspired by a fellow summiteer, and it can be used to make a very generic backup of your AD sites and services database. Before making a ton of changes to it with an automated script.

If you have any questions about the code or Meta Programming in general please don't hesitate to contact me.
