### WSUS Import Automation ###


PLEASE NOTE: This script is a work-in-progress and the approve-nonsuperseded function is currently inoperable.

The goal of this script is simplify the update process of monthly wsus patching inside disconnected environments. Each step is a function which can be turned on or off.

Prerequisites: Make sure this script, the start cmd, and the xml.gz metadata file are all located in the same root directory as the new wsuscontent folder you're bringing to your environment. Otherwise, various environmental variables will not function correctly.

Function specifics:

1. Transfer-Content: This function will transfer all content inside the wsuscontent folder from the drive you're using into the wsuscontent folder of your WSUS server.

2. Import-Metadata: This function runs the wsusutil.exe tool located on your WSUS server to import the latest metadata file on your drive for your WSUS server.

3. Clean-WSUS: This function runs the server cleanup wizard inside your WSUS server to decline any superseded, expired and obsolete updates.

4. Decline-Superseded: This function declines any superseded updates in your console (more often than not the server cleanup wizard will miss various superseded updates.)

5. Approve-Nonsuperseded: This function creates a dummy Computer Group on your WSUS server called "Update Testing," and then approves any updates newer than the patch day you've specified that are not superseded into this computer group, which will install those files to your console.