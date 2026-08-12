Main Point: Narrative needs to be more cohesive

You are the product company. Focus on the changes you want to make as a PROVIDER. Which means all the requirements you state must come from your perspective.

**Situation**

Your operations have gone international. Orders have increased from customers. Load is increasing on your system, and you want to provide a better experience for them. You want to change the following -

- Introduce Pagination, so that clients can view more records in a better manner.  
    For that in GET /orders, you change the following -   
    1. Introduce an optional size field (COMPATIBLE)  
    2. Introduce a mandatory offset field (INCOMPATIBLE)   
    
- Process order creation asynchronously to handle load.  
    For that, you change POST /orders from status 201 to 202.   
    You want to acknowledge the order and then create it in the background. (INCOMPATIBLE).  
    This will break existing consumers.  
    
- Change `orderID` from an integer to a UUID  
    You will run out of `orderID's` with `int64`. So you want to change the orderIds to unique UUIDs.  
    This will be a breaking change you deliberately want to introduce. So you **bump** **up the version to V2**. And phase out your consumers gradually.  
    
- Provide detailed information on orders  
    As orders have increased, you want to provide richer information including -   
      
    - Last update time on order.  
    - Miscellaneous comments/reasons.  
      
    At first, you change the STATUS from a string Enum to an array of objects. However on the main field, this does not work. (INCOMPATIBLE).  
      
    Instead, you must introduce a field call UPDATES which contains an array of objects with the fields.  
    (COMPATIBLE)


Merge should ACTUALLY be blocked when an example is shown in CI
