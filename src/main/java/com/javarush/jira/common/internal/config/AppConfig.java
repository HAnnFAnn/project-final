package com.javarush.jira.common.internal.config;

import com.fasterxml.jackson.annotation.JsonAnyGetter;
import com.fasterxml.jackson.annotation.JsonAutoDetect;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.hibernate5.jakarta.Hibernate5JakartaModule;
import com.javarush.jira.common.util.JsonUtil;
import liquibase.exception.LiquibaseException;
import liquibase.integration.spring.SpringLiquibase;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.*;
import org.springframework.core.env.Environment;
import org.springframework.core.env.Profiles;
import org.springframework.http.ProblemDetail;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.jdbc.datasource.embedded.EmbeddedDatabaseBuilder;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;

import javax.sql.DataSource;
import java.util.Collections;
import java.util.Map;
import java.util.concurrent.Executor;

import static com.fasterxml.jackson.annotation.JsonAutoDetect.Visibility.ANY;
import static com.fasterxml.jackson.annotation.JsonAutoDetect.Visibility.NONE;
import static org.springframework.jdbc.datasource.embedded.EmbeddedDatabaseType.H2;

@Configuration
@Slf4j
@EnableCaching
@RequiredArgsConstructor
@EnableScheduling
@PropertySource({"classpath:application.yaml"})
public class AppConfig {

    private final AppProperties appProperties;
    private final Environment env;

    @Value("${spring.datasource.url}")
    private String postgresUrl;

    @Value("${spring.datasource.username}")
    private String postgresUserName;

    @Value("${spring.datasource.password}")
    private String postgresPassword;

    @Bean("mailExecutor")
    Executor getAsyncExecutor() {
        return new ThreadPoolTaskExecutor() {
            {
                setCorePoolSize(appProperties.getMailSendingProps().corePoolSize);
                setMaxPoolSize(appProperties.getMailSendingProps().maxPoolSize);
                setThreadNamePrefix("mail-");
            }
        };
    }

    public boolean isProd() {
        return env.acceptsProfiles(Profiles.of("prod"));
    }

    public boolean isTest() {
        return env.acceptsProfiles(Profiles.of("test"));
    }

    @Autowired
    void configureAndStoreObjectMapper(ObjectMapper objectMapper) {
        objectMapper.registerModule(new Hibernate5JakartaModule());
        // https://stackoverflow.com/questions/7421474/548473
        objectMapper.addMixIn(ProblemDetail.class, MixIn.class);
        JsonUtil.setMapper(objectMapper);
    }

    //    https://stackoverflow.com/a/74630129/548473
    @JsonAutoDetect(fieldVisibility = NONE, getterVisibility = ANY)
    interface MixIn {
        @JsonAnyGetter
        Map<String, Object> getProperties();
    }

    @Profile("prod")
    @Bean
    public DataSource dataSource() {
        return DataSourceBuilder.create()
                .url(postgresUrl)
                .username(postgresUserName)
                .password(postgresPassword)
                .build();
    }

    @Profile("test")
    @Bean
    public DataSource dataSourceForTests() {
        return DataSourceBuilder.create()
                .driverClassName("org.h2.Driver")
                .url("jdbc:h2:mem:jira-test;NON_KEYWORDS=VALUE")
                .username("jira")
                .password("JiraRush")
                .build();
    }

    @Bean
    public SpringLiquibase liquibase() throws LiquibaseException {
        SpringLiquibase liquibase = new SpringLiquibase();
        if (isProd()) {
            liquibase.setDataSource(dataSource());
            liquibase.setChangeLog("classpath:changelog.xml");
        }
        else if(isTest()) {
            liquibase.setDataSource(dataSourceForTests());
            liquibase.setChangeLog("classpath:changelog-test.xml");
        }
        return liquibase;
    }
}
