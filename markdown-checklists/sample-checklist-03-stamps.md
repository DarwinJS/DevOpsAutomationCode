## Sample Checklist Using Stamps for "Done" Marking

Requires Typora and CopyQ.

### Preparation

Section start: <span style="background-color:lightgreen;border: 1px">**[STARTED 07/25/2019 @ 08:20]**</span>

1. <span style="background-color:lightgreen;border: 1px">**[DONE 07/25 @ 08:23]**</span> Setup widget masher with the following command:
   `widget masher on`

2. <span style="background-color:lightgreen;border: 1px">**[DONE 07/25 @ 08:24]**</span> Record result of masher command:

   <span style="color:red">**RECORD OUTPUT:**</span> "masher enabled"

3. <span style="background-color:lightgreen;border: 1px">**[DONE 07/25 @ 08:29]**</span> Install CopyQ with following command and screenshot the result.

   `chocolatey install -y copyq`

   <span style="color:red">**RECORD SCREENSHOT:**</span>

    ![1564057667184](1563976614625.png)

4. <span style="background-color:salmon;border: 1px">**[SKIPPED 07/25 @ 08:32 Will Be No Interruption]**</span> Setup a maintenance window in pager duty at this url: https://pagerduty.com/thisservice/window

5. <span style="background-color:lightblue;border: 1px">**[TODO]**</span> Setup the production rollout with these settings:

   | Setting Name | Setting Value |
   | ------------ | ------------- |
   | Production   | True          |
   | RolloutRate  | 40            |

### Begin Deployment

1. <span style="background-color:lightblue;border: 1px">**[TODO]**</span> Kickoff the masher deployment with this command:
   `masher deploy production now`

2. <span style="background-color:lightblue;border: 1px">[**TODO]**</span> Wait for completion and record completion time.

   <span style="color:red">**COMPETION DURATION:**</span> <span style="background-color:red;border: 1px">**[RECORD RESULT HERE]**</span> 