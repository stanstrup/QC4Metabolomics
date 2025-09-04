# What is QC4Metabolomics and why do you need it?



**[Slide 2 - the fake]**

Hello. In this video I will introduce the software `QC for Metabolomics`. So perhaps I should start with what `QC4Metabolomics` is... But I won't do that. Instead I will start with the problem it's trying to solve.

**[Slide 3 - the problem]**

And that problem is how to do comprehensive quality control when you do untargeted metabolomics experiments using LC-MS.

The basic problem is the amount of data. Each sample measures thousands of peaks, so how can you know that the data is really a correct representation of your sample?

To go into a bit more detail, the main issue is how to check the data comprehensively and across samples. You cannot manually do that because there are too many peaks, not all problems are apparent to the eye, minor peaks are covered by major peaks and even if you did try to do this you'd need a very experienced operator to catch the problems.

**[Slide 4 - spot checking]**

So what people end up doing is spot-checking the data during analysis or maybe only for a few samples at the beginning. Then all the data is recorded -- time goes by -- and then the poor PhD-student gets around to analysing the data 2 months later... do a PCA... and see that the data is all over the place...

**[Slide 5 - post analysis]**

What to do now? Well you can try to fix the data by filtering out contaminants or correcting a decrease in the signal -- or you can even try to 
re-calibrate the m/z values in the data. But it will never be as good as collecting good data in the first place and the data might be beyond the point where you can re-create useable data.

So either you live with your poor data -- or you go back to the lab and spend more time and money re-analyzing your samples.

But what if you could have fixed the problem when you analyzed the samples in the first place? For that you need some tool that - in real-time - figures out if something is wrong. And that is what QC4metabolomics tries to do for you!

So what does it do?

**[slide 6 - what is it]**

The key idea is to take a selection of compounds and monitor them automatically as soon as the instrument is done acquiring a file.
We can then plot statistics that show if the instrument is stable.

So that is what QC4metabolomics does. It monitors your LC-MS in real-time **as** the analysis is **happening**, so that you can deal with the problem right now before its too late.

**[slide 7]**

The setup looks something like this. You can have multiple machines that record data. This is typically done in a proprietary format so QC4metabolomics also includes an automatic convert that converts to mzML format.

The different modules in QC4metabolomics can do different automated analyses on the data. That could be checking the accuracy of specific peaks and screening for contaminants. All these results are saved in a database and then you can easily investigate the data in a web interface.

The best way to explain is to show so let me show you what the web interface looks like in action.

--------

## Part 2: The walkthrough

Alright, let’s jump into `QC4Metabolomics` and see what it can do.

When you first open the dashboard, you get an overview of all the files that have been added to QC4Metabolomics. At the top, you can pick your instrument, your project, ionization mode, and the date range.
You can also subset to only files with a certain sample ID. You can see that you have several tabs and in each of these you find different ways to examine your data.

Lets go through it one thing at a time. I have already put in a date range, where I know there is interesting data. [`2022-05-30`, `2023-04-09`].

Before I start, let me just **disclaim** that the system was NOT in use when this data was created. Any issues I show you now are exactly why we implemented this QC system in the lab.

OK, lets get back to the program.

On this first tab we land on we have the `Track Compounds` module. In the first plot you see the retention time relative to the expected value for the set of compounds I have chosen to track. It is a bit messy when you look at all compounds at the same time, so let me just limit to tryptophan.

We can hover over a sample to exactly what sample it is....
We can see in this first batch of compounds the samples are around 0.05 min from the target we set and they are with 0.02 mins between each other, with the exception of these few samples that behaved worse. It might already here be worth investigating why. But anyway then positive mode was done, and then when the next batch in negative mode was run suddenly the retention times were all over the place! Not good. We will get back to why that happened.

Lets scroll down and take a look at the m/z values.

If we again start by the first batch here we can see that it is systematically offset. So that indicates a calibration issue. In positive mode it start out ok being plus, minus 10 ppm apart from the offset. There are two samples here that stand out. If we hover over them we can see that it is a diluted sample and a blank sample. So it probably had trouble finding the right peak.

But then something went horribly wrong and the ppm goes off. Even of to 60 ppm off. So something definitely happened here that would have been nice to know during acquisition. Without this plot, I probably wouldn’t notice until later when pre-processing became problematic.

Lets take a look at the intensities. Again lets just look at tryptophan in negative mode. That is where the problem was. Since we have all the samples it can be a bit difficult to see what is going on. So lets restrict to just the `Global-pool-is|Global pool IS` samples.

Ahhh. Now we can see what happened. For the batch with the poor mass precision we can see that the intensity dropped off to more or less nothing. So probably the signal became so low that the mass accuracy suffered. So it would have been good to stop the instrument here and figure out what the problem is. Of course back then we didn't have this tracking unfortunately. For the next project the problem was evidently solve even though we see a bit worrying intra-batch drift here.



Let’s move on from this sad story and check the **Contaminants tab**.

First lets look at the same data as before, so I set the dates. We can also go a bit deeper and decrease the threshold for which contaminants we want to include. You can also set if you want to look at the maximum intensity or the mean intensity in each sample. "Max" is good for contaminants that behave like a peak, while mean or median might be better for contaminants that have a constant presence.

It's like a crime scene investigator for your LC-MS. In the heatmap, each row is a known contaminant and the color shows the intensity.

For example you can see here, that suddenly Erucamide stands out and then goes away. Lets investigate that more in detail by going to the "time view tab". Here we can choose that specific contaminant [erucamide] and follow it over time. We can see that it more or less only appears in one batch of samples. So it would be nice to investigate what makes these sample unique.

Finally we could also go to the last tab here and select a specific sample [M240 Hotfacets_20220926_Sold_058]. Then you can an overview of all the contaminants that have been found. We can zoom into the start here and see which are the most prominent contaminants. So here it would be acetonitrile followed by Erucamide and a PEG and a lot of other  detergent related ions. Also DMSO is listed but in this case it might not really be DMSO, I think, since that is not a solvent we use. So... of course when you screen for 800 contaminants you might sometimes get false hits. But it gives a general idea about what kind of stuff is in the and in particular if something changed from previous analyses.

We also have a **Productivity tab**. That simply shows which projects were run when, and how many samples were run each day.

Then we can move on to the **Warnings tab**.
Here’s where you set your own limits — for example, here it is set to email me if the m/z deviation goes above 40 ppm. But you can set limits based on any of the statistics.
So this is your safe-guard. To detect m/z accuracy issue you'd  not need to check manually. The system will notify you of the problem.



There is also a "log" tab where you can see what the system is doing.

And a "debug" tab where you can see technical details about the system.



That was the tour as of August 2024. You can check the github page for new updates.
Make sure also to read the paper. You can find the link in the description.
And there is also a link to the full documentation.

If you want to try the system then visit the link in the description that shows a video of how to run the demo on your own.






# Running the QC4Metabolomics Demo

------

**Narrator (voiceover):**
Hello! In this video, I’ll walk you through how to set up and run the QC4Metabolomics demo.

We’ll start with downloading the setup files, then launch the demo, explore some features, and finally enable email warnings and backups. You can also find a written version of the tutorial in the video description.

------

## Part 1: Installation

**[On-screen: Open terminal, highlight “create a new folder”]**

**Narrator:**
First, make sure you the required prerequisites which means Docker and docker compose.

Let’s start by creating a folder where you want to install QC4Metabolomics. In this example I am using docker through WSL on windows. I will use a WSL ubuntu instance in this example, but there are instructions to do the same from a windows terminal in the written documentation.

### Linux or WSL

**[On-screen: Type commands]**

Run these commands to download and unzip the demo data:

```bash
wget https://github.com/stanstrup/QC4Metabolomics/releases/latest/download/QC4Metabolomics-demo.zip
unzip QC4Metabolomics-demo.zip
rm QC4Metabolomics-demo.zip
```



------

## Part 2: Launching the Demo

**[On-screen: Show demo folder contents, highlight docker-compose_demo.yml]**

**Narrator:**
 Once the files are ready, launch the demo with Docker Compose:

```bash
docker compose --file docker-compose_demo.yml up --build --force-recreate
```

The first time it runs it will pull the newest program files.



Now, open your browser and go to **localhost**. That means that the app by default runs on port 80.

On the first launch, it may take a few minutes to initialize the database. If you see an error message like *“No tables in the DB”*, don’t worry—it just means initialization is still running.

------

## Part 3: Getting Started with the Demo

**[On-screen: Show browser UI of QC4Metabolomics]**

**Narrator:**
 When the app loads, you’ll notice there are no plots yet.

Click on the **“Contaminants”** tab. If nothing appears, grab a coffee and wait a minute—the system checks for new files every 60 seconds. Once analysis is complete, the plot will load.

Now, try adjusting the *“Minimum intensity in any sample”*. For example, set it to 10³, and you’ll see which contaminants are most common.

------

## Part 4: Tracking Specific Compounds

**[On-screen: Navigate to Track Compounds → Compound Settings]**

**Narrator:**
 Next, let’s track a specific compound—Tryptophan.

Go to **Track Compounds → Compound Settings**, and enter these values that you find in the written tutorial:

| Compound name | Instrument | Mode | m/z      | RT1  |
| ------------- | ---------- | ---- | -------- | ---- |
| L-Tryptophan  | Sold       | pos  | 188.0706 | 2.55 |
| L-Tryptophan  | Sold       | neg  | 203.0826 | 2.55 |

Click **Submit** for each entry. After a few minutes, refresh the browser, and you’ll see Tryptophan data under **Compound stats**.



Now the data is ready. We can see how the retention times deviates very slightly from the expected value we entered. and we can see teh same for the m/z value. You can explore the other tabs on your own.



------

## Part 5: Enabling Email Warnings

**[On-screen: Open `settings_demo.env` in a text editor]**

**Narrator:**
 By default, email warnings are off. To enable them, open the file `settings_demo.env`.

Scroll down to the **Warner module** section, and set:

```ini
QC4METABOLOMICS_module_Warner_enabled=TRUE
```

Now add your email settings. For Gmail, you’ll need an **App Password**, not your regular Gmail password. See the written tutorial for a link that shows how to do this with gmail.

Here’s an example:

```ini
QC4METABOLOMICS_module_Warner_email_from=EMAIL_SENDER
QC4METABOLOMICS_module_Warner_email_to=EMAIL_RECEIVER
QC4METABOLOMICS_module_Warner_email_user=YOUR_USER
QC4METABOLOMICS_module_Warner_email_password=YOUR_PASSWORD
QC4METABOLOMICS_module_Warner_email_host=smtp.gmail.com
QC4METABOLOMICS_module_Warner_email_port=587
QC4METABOLOMICS_module_Warner_email_use_ssl=TRUE
```

Stop QC4Metabolomics with **Ctrl + C**, then restart it with the same Docker command as before.

**[On-screen: Show “Warning rules” tab]**

Now, go to the **Warning rules** tab.

Here’s a sample rule to catch any file where the *m/z* deviation is more than 30 ppm:

| Rule Name        | Instrument | Statistics | Operator | Value | Absolute? |
| ---------------- | ---------- | ---------- | -------- | ----- | --------- |
| PPM out of range | Sold       | mz_dev_ppm | >        | 30    | TRUE      |

Any matching file will trigger an email notification. If you email settings are correct you will receive an email shortly.

------

## Part 6: Backups

**[On-screen: Highlight `backups` folder]**

**Narrator:**
 QC4Metabolomics automatically backs up the database to the **backups** folder.

You can adjust the backup frequency in the settings file.

------

## Part 7: Updating

**[On-screen: Terminal, run update command]**

**Narrator:**
 Finally, to update the demo with the latest images, run:

```bash
docker compose --file docker-compose_demo.yml pull
```

and then start it again with the same command you used to start it in the first place:

```bash
docker compose --file docker-compose_demo.yml up --build --force-recreate
```



------

**[Closing Scene: Title card “QC4Metabolomics Demo – Complete”]**

**Narrator:**
 And that’s it! 

Thanks for watching and I hope you will find QC4metabolomics useful.



# Notes for "story of the paper"

* end of 2014 I wrote a grant for the Villum foundation suggestion an automated QC system. This was less than a year after I had started on another villum postdoc grant.... --> rejected
* in march 2016 I instead started at steno diabetes center. --> they already had a system very similar to what I had described -->
* was not scaleable. unusably slow. -->
* the guy that made it left to be a manager at Novo. -->
* I started working on a replacement. also tried to get grants to do it but no luck.
* Then I move to PLEN after 1.5 year. Lets not get into all the mess that happened at Steno. Otherwise it will be a long story.
* Then I got back here in in 2018 and it was relevant again. But many things to do. Never got around to finishing the paper. -->
* Started writing on the paper again in 2023 and fixed many things in the software. -->
* Got it submitted last christmas. -->
* And now it is finally out.
