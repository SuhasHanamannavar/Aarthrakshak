package com.aarthrakshak.websocket;

import com.aarthrakshak.model.dto.TransactionDTO;
import com.aarthrakshak.model.entity.Transaction;
import com.aarthrakshak.repository.TransactionRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;

@Component
public class TransactionWebSocketHandler extends TextWebSocketHandler {

    private final List<WebSocketSession> sessions = new CopyOnWriteArrayList<>();
    private final TransactionRepository transactionRepository;
    private final ObjectMapper objectMapper;

    public TransactionWebSocketHandler(TransactionRepository transactionRepository) {
        this.transactionRepository = transactionRepository;
        this.objectMapper = new ObjectMapper();
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        sessions.add(session);
        sendInitialTransactions(session);
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        sessions.remove(session);
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        // Echo back or handle incoming messages if needed
    }

    public void broadcastTransaction(Transaction transaction) {
        try {
            TransactionDTO dto = TransactionDTO.fromEntity(transaction);
            String json = objectMapper.writeValueAsString(dto);
            TextMessage msg = new TextMessage(json);
            for (WebSocketSession s : sessions) {
                if (s.isOpen()) {
                    try {
                        s.sendMessage(msg);
                    } catch (IOException e) {
                        sessions.remove(s);
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void sendInitialTransactions(WebSocketSession session) {
        try {
            List<Transaction> recent = transactionRepository.findAllByOrderByTransactionDateDesc();
            for (Transaction t : recent) {
                TransactionDTO dto = TransactionDTO.fromEntity(t);
                String json = objectMapper.writeValueAsString(dto);
                session.sendMessage(new TextMessage(json));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
