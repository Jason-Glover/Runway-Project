from __future__ import print_function
import boto3
import uuid


# Function to supply Code Pipeline with Job Success result
code_pipeline = boto3.client('codepipeline')
def put_job_success(job, message):
    print('Putting job success')
    print(message)
    code_pipeline.put_job_success_result(jobId=job)


# Function to supply Code Pipeline with Job Failure result
code_pipeline = boto3.client('codepipeline')
def put_job_failure(job,message):
    print('Putting job failure')
    print(message)
    code_pipeline.put_job_failure_result(jobId=job, failureDetails={
            'message': message,
            'type': 'JobFailed'
        }
    )


# Function to grab all Service Catalog Portfolios
def list_portfolios():
    nextmarker = None
    done = False
    client = boto3.client('servicecatalog')
    lst_portfolio = []

    while not done:
        if nextmarker:
            portfolio_response = client.list_portfolios(nextmarker=nextmarker)
        else:
            portfolio_response = client.list_portfolios()

        for portfolio in portfolio_response['PortfolioDetails']:
            lst_portfolio.append(portfolio)

        if 'NextPageToken' in portfolio_response:
            nextmarker = portfolio_response['NextPageToken']
        else:
            break
    return lst_portfolio
    print('portfolio',portfolio_response)


# Function to list all products in Service Catalog Portfolios
def list_products_for_portfolio(id):
    nextmarker = None
    done = False
    client = boto3.client('servicecatalog')
    lst_products = []

    while not done:
        if nextmarker:
            product_response = client.search_products_as_admin(PageToken=nextmarker, PortfolioId=id)
        else:
            product_response = client.search_products_as_admin(PortfolioId=id)

        for product in product_response['ProductViewDetails']:
            lst_products.append(product['ProductViewSummary'])

        if 'NextPageToken' in product_response:
            nextmarker = product_response['NextPageToken']
        else:
            break
    return lst_products
    print('product', product_response)


# Function to create Launch constraints for products in Service Catalog Portfolios
def create_constraint(portfolio_id, products_id, type_constraint, service_role):
    client = boto3.client('servicecatalog')
    cr_response = client.create_constraint(
        PortfolioId=portfolio_id,
        ProductId=products_id,
        Parameters=str(service_role),
        Type=type_constraint,
        IdempotencyToken=str(uuid.uuid4())
    )
    print(cr_response)


# Main Code block to tie all functions together and create launch constraint
def lambda_handler(event, context):
    job_id = event['CodePipeline.job']['id']
    job_data = event['CodePipeline.job']['data']
    service_role = job_data['actionConfiguration']['configuration']['UserParameters']
    print(service_role)
    print(event)
    lst_portfolio = list_portfolios()


    try:
        for item in lst_portfolio:
            portfolio_id = item['Id']
            lst_products = list_products_for_portfolio(portfolio_id)
            for products in lst_products:
                products_id = (products['ProductId'])
                type_constraint = 'LAUNCH'
                try:
                    create_constraint(portfolio_id, products_id, type_constraint, service_role)
                    print(portfolio_id, products_id, "Constraint created")
                except:
                    print(portfolio_id, products_id, 'Constraint already exists')
        put_job_success(job_id, 'Constraints created successfully')
    except Exception as e:
        print(e)
        put_job_failure(job_id,'Constraint failed to create')
