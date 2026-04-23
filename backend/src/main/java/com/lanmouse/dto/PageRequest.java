package com.lanmouse.dto;

import lombok.Data;

@Data
public class PageRequest {
    private int page = 1;
    private int size = 20;
    private String sortBy = "id";
    private String sortOrder = "desc";

    public long getOffset() {
        return (long) (page - 1) * size;
    }
}
