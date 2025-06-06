package com.diyauth.aop;

import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.reflect.MethodSignature;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.util.StopWatch;

@Aspect
@Component
public class LoggingAspect {
    
    private static final Logger logger = LoggerFactory.getLogger(LoggingAspect.class);
    
    /**
     * This method uses Around advice which ensures that an advice can run before
     * and after the method execution, to and log the method name, arguments, 
     * and execution time.
     */
    @Around("@within(org.springframework.web.bind.annotation.RestController) || " +
             "@within(org.springframework.stereotype.Controller)")
    public Object logMethodExecutionTime(ProceedingJoinPoint proceedingJoinPoint) throws Throwable {
        MethodSignature methodSignature = (MethodSignature) proceedingJoinPoint.getSignature();
        
        // Get intercepted method details
        String className = methodSignature.getDeclaringType().getSimpleName();
        String methodName = methodSignature.getName();
        
        // Log method entry with arguments
        logger.info("Executing {}.{}() with arguments: {}", 
            className, methodName, getArgsAsString(proceedingJoinPoint.getArgs()));
        
        // Measure method execution time
        StopWatch stopWatch = new StopWatch();
        stopWatch.start();
        
        try {
            // Execute the method
            Object result = proceedingJoinPoint.proceed();
            
            stopWatch.stop();
            
            // Log method exit with execution time
            logger.info("Completed {}.{}() in {} ms with result: {}", 
                className, methodName, stopWatch.getTotalTimeMillis(), 
                result != null ? result.toString() : "void");
            
            return result;
            
        } catch (Exception e) {
            stopWatch.stop();
            
            // Log error with execution time
            logger.error("Error in {}.{}() after {} ms: {}", 
                className, methodName, stopWatch.getTotalTimeMillis(), 
                e.getMessage(), e);
                
            throw e;
        }
    }
    
    private String getArgsAsString(Object[] args) {
        if (args == null || args.length == 0) {
            return "[]";
        }
        
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < args.length; i++) {
            if (i > 0) {
                sb.append(", ");
            }
            if (args[i] != null) {
                // For security, don't log sensitive data like passwords
                if (args[i] instanceof String) {
                    String str = (String) args[i];
                    if (str.toLowerCase().contains("password") || str.toLowerCase().contains("secret")) {
                        sb.append("*****");
                        continue;
                    }
                }
                sb.append(args[i]);
            } else {
                sb.append("null");
            }
        }
        sb.append("]");
        return sb.toString();
    }
}
