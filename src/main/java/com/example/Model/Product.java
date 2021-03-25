package com.example.Model;

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * SPDX-License-Identifier: MIT-0
 */
public class Product
{
    public String productId;
    public String productName;
    public String productVersion;

    public String getProductId(){
        return productId;
    }

    public String getProductName(){
        return productName;
    }
    public String getProductVersion(){
        return productVersion;
    }

    public void setProductId(String productId){
        this.productId = productId;
    }

    public void setProductName(String productName){
        this.productName = productName;
    }
    public void setProductVersion(String productVersion){
        this.productVersion = productVersion;
    }
}