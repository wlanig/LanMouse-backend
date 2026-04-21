package com.lanmouse;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@MapperScan("com.lanmouse.mapper")
public class LanmouseApplication {

    public static void main(String[] args) {
        SpringApplication.run(LanmouseApplication.class, args);
    }
}
