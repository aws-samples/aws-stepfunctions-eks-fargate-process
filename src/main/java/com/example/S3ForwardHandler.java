package com.example;

import com.amazonaws.services.kinesis.AmazonKinesis;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.ScheduledEvent;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.util.StringUtils;
import com.example.Utils.ConfigReader;
import com.example.Utils.DataProcessor;
import com.google.gson.Gson;


/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * SPDX-License-Identifier: MIT-0
 */

public class S3ForwardHandler implements RequestHandler<ScheduledEvent, Object> {

    Boolean processS3 = false;
    String clientRegion = "";
    String bucketName = "";
    String kinesisStream = "";
    DataProcessor dataProcessor;

    public S3ForwardHandler() throws Exception {
        System.out.println("default constructor");
        this.clientRegion = System.getenv("REGION");
        this.bucketName = System.getenv("S3_BUCKET");
        this.kinesisStream = System.getenv("STREAM_NAME");
        this.processS3 = Boolean.valueOf(System.getenv("PROCESS_S3"));
        
        if(StringUtils.isNullOrEmpty(this.clientRegion)){
            this.clientRegion = ConfigReader.getPropertyValue("REGION");
            this.bucketName = ConfigReader.getPropertyValue("S3_BUCKET");
            this.kinesisStream = ConfigReader.getPropertyValue("STREAM_NAME");
            this.processS3 = Boolean.valueOf(ConfigReader.getPropertyValue("PROCESS_S3"));
            System.out.println(String.format("Default Constructor ConfigReader - Client Region: %s, Bucket Name: %s, Stream Name: %s, Process S3: %s", this.clientRegion, this.bucketName, this.kinesisStream, String.valueOf(this.processS3)));
        }
        if(this.clientRegion == "<YOUR_ACCOUNT_REGION>"){
            throw new Exception("Unable to retrieve Environment Variables!");
        }
        dataProcessor = new DataProcessor(this.clientRegion);
        System.out.println(String.format("Default Constructor - Client Region: %s, Bucket Name: %s, Stream Name: %s, Process S3: %s", this.clientRegion, this.bucketName, this.kinesisStream, String.valueOf(this.processS3)));
    }

    public S3ForwardHandler(String clientRegion, String bucketName, String kinesisStream, AmazonS3 s3Client, AmazonKinesis kinesisClient, Gson gson) {
        System.out.println("test constructor");
        this.clientRegion = clientRegion;
        this.bucketName = bucketName;
        this.kinesisStream = kinesisStream;
        this.processS3 = Boolean.valueOf(System.getenv("PROCESS_S3"));
        if(StringUtils.isNullOrEmpty(this.clientRegion)){
            this.clientRegion = ConfigReader.getPropertyValue("REGION");
            this.bucketName = ConfigReader.getPropertyValue("S3_BUCKET");
            this.kinesisStream = ConfigReader.getPropertyValue("STREAM_NAME");
            this.processS3 = Boolean.parseBoolean(ConfigReader.getPropertyValue("PROCESS_S3"));
            System.out.println(String.format("Default Constructor ConfigReader - Client Region: %s, Bucket Name: %s, Stream Name: %s, Process S3: %s", this.clientRegion, this.bucketName, this.kinesisStream, String.valueOf(this.processS3)));
        }
        dataProcessor = new DataProcessor(s3Client, kinesisClient, gson);
        System.out.println(String.format("Test Constructor - Client Region: %s, Bucket Name: %s, Stream Name: %s", this.clientRegion, this.bucketName, this.kinesisStream));
    }

    @Override
    public Object handleRequest(ScheduledEvent input, Context context) {

        String success_response = "Processing S3 Forward Handler ";
        System.out.println(success_response);

        try {
            if(processS3){
                System.out.println("Environment variable turned ON for Processing");
                dataProcessor.sendS3ContentsToKinesis(clientRegion, bucketName, kinesisStream);
            }
            else{
                System.out.println("Environment variable turned OFF for Processing");
            }
            
        } 
        //catch (IOException e) {
        catch (Exception e) {
            e.printStackTrace();
        }
        return success_response;

    }

    public static void main(String[] args) throws Exception {
        new S3ForwardHandler().handleRequest(new ScheduledEvent(), null);
    }
}