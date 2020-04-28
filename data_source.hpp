#include <vector>
#include <algorithm>
#include <iostream>
#include <cstdlib>
#include <vector_types.h>

struct DataGenerator
{
    using PointType = float4;

    std::size_t data_size;
    std::size_t tests_num;

    float cube_size;
    float max_radius;

    float shared_radius;

    std::vector<PointType> points;
    std::vector<PointType> queries;
    std::vector<float> radiuses;
    std::vector< std::vector<size_t> > bfresutls;

    std::vector<size_t> indices;

    DataGenerator() : data_size(871000), tests_num(10000), cube_size(1024.f)
    {
        max_radius    = cube_size/15.f;
        shared_radius = cube_size/20.f;
    }

    void operator()()
    {
        srand (0);

        points.resize(data_size);
        for(std::size_t i = 0; i < data_size; ++i)
        {
            points[i].x = ((float)rand())/RAND_MAX * cube_size;
            points[i].y = ((float)rand())/RAND_MAX * cube_size;
            points[i].z = ((float)rand())/RAND_MAX * cube_size;
        }


        queries.resize(tests_num);
        radiuses.resize(tests_num);
        for (std::size_t i = 0; i < tests_num; ++i)
        {
            queries[i].x = ((float)rand())/RAND_MAX * cube_size;
            queries[i].y = ((float)rand())/RAND_MAX * cube_size;
            queries[i].z = ((float)rand())/RAND_MAX * cube_size;
            radiuses[i]  = ((float)rand())/RAND_MAX * max_radius;
        };

        for(std::size_t i = 0; i < tests_num/2; ++i)
            indices.push_back(i*2);
    }

    void bruteForceSearch(bool log = false, float radius = -1.f)
    {
        if (log)
            std::cout << "BruteForceSearch";

        size_t value100 = std::min<size_t>(tests_num, 50);
        size_t step = tests_num/value100;

        bfresutls.resize(tests_num);
        for(std::size_t i = 0; i < tests_num; ++i)
        {
            if (log && i % step == 0)
            {
                std::cout << ".";
                std::cout.flush();
            }

            std::vector<size_t>& curr_res = bfresutls[i];
            curr_res.clear();

            float query_radius = radius > 0 ? radius : radiuses[i];
            const PointType& query = queries[i];

            for(std::size_t ind = 0; ind < points.size(); ++ind)
            {
                const PointType& point = points[ind];

                float dx = query.x - point.x;
                float dy = query.y - point.y;
                float dz = query.z - point.z;

                if (dx*dx + dy*dy + dz*dz < query_radius * query_radius)
                    curr_res.push_back(ind);
            }

            std::sort(curr_res.begin(), curr_res.end());
        }
        if (log)
            std::cout << "Done" << std::endl;
    }

    void printParams() const
    {
        std::cout << "Points number  = " << data_size << std::endl;
        std::cout << "Queries number = " << tests_num << std::endl;
        std::cout << "Cube size      = " << cube_size << std::endl;
        std::cout << "Max radius     = " << max_radius << std::endl;
        std::cout << "Shared radius  = " << shared_radius << std::endl;
    }

    template<typename Dst>
    struct ConvPoint
    {
        Dst operator()(const PointType& src) const
        {
            Dst dst;
            dst.x = src.x;
            dst.y = src.y;
            dst.z = src.z;
            return dst;
        }
    };
};