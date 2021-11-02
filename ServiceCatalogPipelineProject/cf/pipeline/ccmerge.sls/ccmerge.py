from __future__ import print_function
from boto3.session import Session
import boto3
import traceback

# BOTO3 Resources to obtain required information
code_pipeline = boto3.client('codepipeline')
code_commit = boto3.client('codecommit')


# Function to supply Code Pipeline with Job Success result
def put_job_success(job, message):
    print('Putting job success')
    print(message)
    code_pipeline.put_job_success_result(jobId=job)


# Function to supply Code Pipeline with Job Failure result
def put_job_failure(job, message):
    print('Putting job failure')
    print(message)
    code_pipeline.put_job_failure_result(jobId=job, failureDetails={
            'message': message,
            'type': 'JobFailed'
        }
    )


# Main Code to Execute the following:
# Create Pull Request
# Merge the Pull Request
# Check the Status of the Pull Request
# Provide Job Result to Code Pipeline
def lambda_handler(event, context):

    print(event)

    try:
        job_id = event['CodePipeline.job']['id']

        # Start Code Block to Create a Pull Request
        create_pr = code_commit.create_pull_request(
                title='Pull Request from dev to master',
                description='pull request for new commit to dev',
                targets=[
                    {
                        'repositoryName': 'service-catalog',
                        'sourceReference': 'dev',
                        'destinationReference': 'master'
                    }
                ]
            )

        pr_id = create_pr['pullRequest']['pullRequestId']
        print('Pull Request ID=' + pr_id)
        print('Create Pull Request', create_pr)
        # End Code Block

        # Start Code Block to Merge the Pull request to the Master Branch
        merge_pr = code_commit.merge_pull_request_by_squash(
            pullRequestId=str(pr_id),
            repositoryName='service-catalog',
            conflictDetailLevel='LINE_LEVEL',
            conflictResolutionStrategy='ACCEPT_SOURCE',
            commitMessage='squash commit via Lambda',
        )
        print('Merge Commit', merge_pr)
        # End Code Block

        # Start Code Block to check the status of the Pull Request
        check_pr = code_commit.get_pull_request(
            pullRequestId=str(pr_id)
        )

        pr_status = check_pr['pullRequest']['pullRequestStatus']
        print('GetPullRequst', check_pr)
        # End Code Block to check the status of the Pull Request

        # Start Code Block to perform actions based on Pull Request Status OPEN
        # or CLOSED and Provide Job Result to Code Pipeline
        if pr_status == 'CLOSED':
            print('Pull Request Status=' + pr_status)
            put_job_success(job_id, 'Pull Request Merged and Closed')
        elif pr_status == 'OPEN':
            print('Pull Request Status=' + pr_status)
            put_job_failure(job_id, 'Pull Request Open, Resolve Conflicts ' +
                                    'and Merge PR then Retry Stage')
        else:
            print('Pull Request Status=' + pr_status)
            put_job_failure(job_id, 'Pull Request Status Not Found')
        # End Code Block

    except Exception as e:
        # Used to Provide Error Exception to Cloud Watch Logs
        print('Function failed due to exception.')
        print(e)
        traceback.print_exc()
        put_job_failure(job_id, 'Function exception: ' + str(e))
