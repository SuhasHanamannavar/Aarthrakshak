package com.aarthrakshak.security;

import com.aarthrakshak.config.SupabaseProperties;
import com.auth0.jwt.JWT;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.exceptions.JWTVerificationException;
import com.auth0.jwt.interfaces.DecodedJWT;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;

@Component
public class SupabaseJwtFilter extends OncePerRequestFilter {

    private final SupabaseProperties supabaseProperties;

    public SupabaseJwtFilter(SupabaseProperties supabaseProperties) {
        this.supabaseProperties = supabaseProperties;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        String path = request.getRequestURI();
        if (path.equals("/ws") || path.startsWith("/ws/")) {
            filterChain.doFilter(request, response);
            return;
        }

        String authHeader = request.getHeader("Authorization");
        if (!StringUtils.hasText(authHeader) || !authHeader.startsWith("Bearer ")) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("{\"error\":\"Missing or invalid Authorization header\"}");
            return;
        }

        String token = authHeader.substring(7);
        try {
            DecodedJWT decoded = null;
            try {
                byte[] decodedKey = java.util.Base64.getDecoder().decode(supabaseProperties.getJwtSecret());
                Algorithm algorithmBase64 = Algorithm.HMAC256(decodedKey);
                decoded = JWT.require(algorithmBase64).build().verify(token);
            } catch (Exception e1) {
                // If it fails (either base64 decoding fails, or signature is invalid), fallback to raw string
                Algorithm algorithmRaw = Algorithm.HMAC256(supabaseProperties.getJwtSecret());
                decoded = JWT.require(algorithmRaw).build().verify(token);
            }

            String userId = decoded.getSubject();
            UsernamePasswordAuthenticationToken auth =
                    new UsernamePasswordAuthenticationToken(userId, null, Collections.emptyList());
            SecurityContextHolder.getContext().setAuthentication(auth);
        } catch (JWTVerificationException e) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("{\"error\":\"Invalid JWT token: " + e.getMessage() + "\"}");
            return;
        }

        filterChain.doFilter(request, response);
    }
}
