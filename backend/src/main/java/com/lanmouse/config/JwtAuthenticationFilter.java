package com.lanmouse.config;

import com.lanmouse.util.JwtUtil;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * JWT 认证过滤器
 */
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private JwtUtil jwtUtil;

    public JwtAuthenticationFilter(JwtUtil jwtUtil) {
        this.jwtUtil = jwtUtil;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        String authHeader = request.getHeader("Authorization");

        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            try {
                if (jwtUtil.validateToken(token)) {
                    String phone = jwtUtil.getPhoneFromToken(token);
                    String role = jwtUtil.getRoleFromToken(token);

                    List<SimpleGrantedAuthority> authorities = "admin".equals(role)
                            ? Collections.singletonList(new SimpleGrantedAuthority("ROLE_ADMIN"))
                            : new ArrayList<>();

                    UsernamePasswordAuthenticationToken authentication =
                        new UsernamePasswordAuthenticationToken(phone, null, authorities);
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }
            } catch (Exception e) {
                // Token 无效，继续执行（让需要认证的接口返回 401）
            }
        }

        filterChain.doFilter(request, response);
    }
}
