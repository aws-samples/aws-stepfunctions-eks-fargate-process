package com.example;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.verify;
import static org.mockito.internal.verification.VerificationModeFactory.times;

import java.io.*;
import java.util.ArrayList;
import java.util.List;

import com.amazonaws.services.kinesis.AmazonKinesis;
import com.amazonaws.services.kinesis.model.PutRecordsRequest;
import com.amazonaws.services.kinesis.model.PutRecordsResult;
import com.amazonaws.services.s3.AmazonS3;
import com.amazonaws.services.s3.model.*;
import org.junit.Before;
import org.junit.Test;
import org.mockito.junit.MockitoJUnitRunner;


import com.example.Model.Product;
import com.google.gson.Gson;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import static org.mockito.Mockito.*;


/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * SPDX-License-Identifier: MIT-0
 */

@RunWith(MockitoJUnitRunner.Silent.class)
public class S3ForwardHandlerTest {

    @Mock
    S3Object s3Object;

    @Mock
    AmazonS3 s3Client;

    @Mock
    ListObjectsV2Result objectListingMock;

    private String bucket = "test-bucket";
    private String keyPath = "path/product1.txt";
    private String stream = "test-stream";

    private List<S3ObjectSummary> listS3ObjectSummary;
    private S3ObjectSummary s3ObjectSummary;

    @Mock
    AmazonKinesis kinesisClient;

    Gson gson;

    private Product inputProduct;
    private List<Product> products = new ArrayList<>();

    S3ForwardHandler s3ForwardHandler;

    @Before
    public void setup() throws Exception{
        gson = new Gson();

        inputProduct = new Product();
        inputProduct.setProductId("1");

        Product product = new Product();
        product.setProductId("1");
        product.setProductName("iphone");
        product.setProductVersion("10R");
        products.add(product);

        s3ObjectSummary = new S3ObjectSummary();
        listS3ObjectSummary = new ArrayList<>();

        s3ObjectSummary.setBucketName(bucket);
        s3ObjectSummary.setKey(keyPath);
        listS3ObjectSummary.add(s3ObjectSummary);

        when(objectListingMock.getObjectSummaries()).thenReturn(listS3ObjectSummary);
        when(objectListingMock.getBucketName()).thenReturn(bucket);

        PutRecordsResult putRecordsResult = new PutRecordsResult();
        when(kinesisClient.putRecords(any())).thenReturn(putRecordsResult);
        when(s3Client.listObjectsV2(any(ListObjectsV2Request.class))).thenReturn(objectListingMock);

        s3ForwardHandler = new S3ForwardHandler(null, null, null, s3Client, kinesisClient, gson);
    }

    @Test
    public void saveS3_validRequest_Success() {

        try {
            String initialString = "{\"productId\": 1 , \"productName\": \"some Name\", \"productVersion\": \"v0\"}";
            S3ObjectInputStream s3ObjectInputStream = new S3ObjectInputStream(new ByteArrayInputStream(initialString.getBytes()), null);
            when(s3Object.getObjectContent()).thenReturn(s3ObjectInputStream);
            when(s3Client.getObject(any(GetObjectRequest.class))).thenReturn(s3Object);

            s3ForwardHandler.handleRequest(null, null);
            verify(s3Client, times(0)).listObjectsV2(bucket);

            PutRecordsRequest putRecordsRequest  = new PutRecordsRequest();
            putRecordsRequest.setStreamName(stream);
            verify(kinesisClient, times(0)).putRecords(putRecordsRequest);
        }
        catch(Exception ex){
            System.out.println(ex.getMessage());
        }
    }


}