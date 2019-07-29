## Sample Checklist Numberd and Using Strikethrough for "Done" Marking

Only Requires Typora

### Preparation

Section start: **[STARTED 07/25/2019 @ 08:20]**

1. ~~Setup widget masher with the following command~~:
   `widget masher on`

2. ~~Record result of masher command:~~

   <span style="color:red">**RECORD OUTPUT:**</span> "masher enabled"

3. ~~Install CopyQ with following command and screenshot the result.~~

   `chocolatey install -y copyq`

   <span style="color:red">**RECORD SCREENSHOT:**</span>

   ![1564057667184](1563976614625.png)

4. Setup a maintenance window in pager duty at this url: https://pagerduty.com/thisservice/window

5. Setup the production rollout with these settings:

   | Setting Name | Setting Value |
   | ------------ | ------------- |
   | Production   | True          |
   | RolloutRate  | 40            |

### Begin Deployment

1. Kickoff the masher deployment with this command:
   `masher deploy production now`

2. Wait for completion and record completion time.

   **COMPLETION DURATION:**