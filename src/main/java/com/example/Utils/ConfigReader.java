package com.example.Utils;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * SPDX-License-Identifier: MIT-0
 */
public class ConfigReader {
    private static Properties prop;

    static{
        InputStream inputStream = null;
        try {
            prop = new Properties();
            // for lower version of Java/JDK less than 11
            inputStream = ClassLoader.class.getResourceAsStream("/application.properties");
            if(inputStream == null) {
                inputStream = ClassLoader.getSystemResourceAsStream("application.properties");
            }
            prop.load(inputStream);
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static String getPropertyValue(String key){
        return prop.getProperty(key);
    }
}
